module Api
  module V1
    module Admin
      class CustomersController < BaseController
        before_action :set_customer, only: [:show, :update, :destroy, :adjust_points, :record_visit, :update_visit]
        before_action :set_visit, only: [:update_visit]

        # GET /api/v1/admin/customers?q=...&active=true|false
        def index
          customers = Customer.all
          customers = customers.where(active: ActiveModel::Type::Boolean.new.cast(params[:active])) if params[:active].present?

          if params[:q].present?
            q = params[:q].to_s.strip
            customers = customers.where("phone ILIKE ? OR name ILIKE ?", "%#{q}%", "%#{q}%")
          end

          customers = customers.recent.limit((params[:limit] || 50).to_i)
          render json: customers.map(&:as_summary_json)
        end

        # GET /api/v1/admin/customers/:id
        def show
          render json: @customer.as_json(
            include: {
              customer_visits: { only: [:id, :source, :occurred_at, :note, :amount_vnd, :booking_id, :admin_id, :created_at] },
              loyalty_transactions: { only: [:id, :kind, :points, :balance_before, :balance_after, :amount_vnd, :reference, :note, :occurred_at, :booking_id, :admin_id, :created_at] }
            }
          )
        end

        # GET /api/v1/admin/customers/lookup?phone=...
        def lookup
          phone = params[:phone].to_s.strip.gsub(/\s+/, '')
          if phone.blank?
            render json: { error: 'phone is required' }, status: :bad_request
            return
          end

          customer = Customer.find_by(phone: phone)
          render json: customer&.as_summary_json
        end

        def create
          customer = Customer.new(customer_params)

          if customer.save
            render json: customer.as_summary_json, status: :created
          else
            render json: { errors: customer.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if @customer.update(customer_params)
            render json: @customer.as_summary_json
          else
            render json: { errors: @customer.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @customer.destroy
          head :no_content
        end

        # POST /api/v1/admin/customers/:id/adjust_points
        # body:
        # - earn/redeem: { kind: 'earn'|'redeem', points: 10, note?: '...', booking_id?: ... }
        # - adjust:      { kind: 'adjust', points: <new_balance>, note?: '...' }
        def adjust_points
          kind = params[:kind].to_s
          points_param = params[:points]
          booking_id = params[:booking_id].presence
          note = params[:note]

          unless LoyaltyTransaction::KINDS.include?(kind)
            render json: { error: 'Invalid kind' }, status: :unprocessable_entity
            return
          end

          tx = nil
          Customer.transaction do
            before = @customer.points_balance.to_i

            if kind == 'adjust'
              new_balance = points_param.to_i
              if new_balance < 0
                render json: { error: 'points (new balance) must be >= 0 for adjust' }, status: :unprocessable_entity
                raise ActiveRecord::Rollback
              end

              delta = new_balance - before
              tx = LoyaltyTransaction.create!(
                customer: @customer,
                admin: current_admin,
                kind: kind,
                points: delta, # store delta for compatibility
                balance_before: before,
                balance_after: new_balance,
                note: note,
                occurred_at: Time.current
              )
              @customer.update!(points_balance: new_balance)
            else
              points = points_param.to_i
              if points == 0
                render json: { error: 'points must be non-zero' }, status: :unprocessable_entity
                raise ActiveRecord::Rollback
              end

              # Enforce redeem as negative delta
              points = -points.abs if kind == 'redeem'
              after = before + points

              tx = LoyaltyTransaction.create!(
                customer: @customer,
                admin: current_admin,
                booking_id: booking_id,
                kind: kind,
                points: points,
                balance_before: before,
                balance_after: after,
                note: note,
                occurred_at: Time.current
              )
              @customer.update!(points_balance: after)
            end
          end

          render json: { customer: @customer.as_summary_json, transaction: tx }, status: :created
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: [e.message] }, status: :unprocessable_entity
        end

        # POST /api/v1/admin/customers/:id/record_visit
        # body: { occurred_at: optional ISO8601, note: '...', booking_id: optional, amount_vnd: optional }
        def record_visit
          occurred_at = params[:occurred_at].present? ? Time.zone.parse(params[:occurred_at].to_s) : Time.current
          booking_id = params[:booking_id].presence
          note = params[:note]
          amount_vnd = params[:amount_vnd].present? ? params[:amount_vnd].to_i : nil

          visit = nil
          Customer.transaction do
            visit = CustomerVisit.create!(
              customer: @customer,
              admin: current_admin,
              booking_id: booking_id,
              source: 'manual',
              occurred_at: occurred_at,
              note: note,
              amount_vnd: amount_vnd
            )

            @customer.total_visits += 1
            @customer.last_visit_at = [@customer.last_visit_at, occurred_at].compact.max
            @customer.total_spent_vnd += amount_vnd if amount_vnd.present? && amount_vnd.positive?
            @customer.save!
          end

          render json: { customer: @customer.as_summary_json, visit: visit }, status: :created
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: [e.message] }, status: :unprocessable_entity
        end

        # PATCH /api/v1/admin/customers/:id/visits/:visit_id
        # body: { occurred_at?: ISO8601, note?: string, amount_vnd?: integer }
        def update_visit
          if @visit.source == 'booking_completed'
            render json: { error: 'Không cho sửa lượt ghé tự động từ booking' }, status: :unprocessable_entity
            return
          end

          old_amount = @visit.amount_vnd.to_i
          new_amount = visit_params.key?(:amount_vnd) ? visit_params[:amount_vnd].to_i : old_amount
          occurred_at = visit_params[:occurred_at].present? ? Time.zone.parse(visit_params[:occurred_at].to_s) : @visit.occurred_at

          Customer.transaction do
            @visit.update!(
              note: visit_params.key?(:note) ? visit_params[:note] : @visit.note,
              amount_vnd: visit_params.key?(:amount_vnd) ? new_amount : @visit.amount_vnd,
              occurred_at: occurred_at
            )

            delta = new_amount - old_amount
            if delta != 0
              @customer.total_spent_vnd += delta
            end

            # occurred_at may affect last_visit_at; recompute cheaply
            @customer.last_visit_at = @customer.customer_visits.maximum(:occurred_at)
            @customer.save! if @customer.changed?
          end

          render json: { customer: @customer.as_summary_json, visit: @visit }
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: [e.message] }, status: :unprocessable_entity
        end

        private

        def set_customer
          @customer = Customer.find(params[:id])
        end

        def set_visit
          @visit = @customer.customer_visits.find(params[:visit_id])
        end

        def visit_params
          params.permit(:occurred_at, :note, :amount_vnd)
        end

        def customer_params
          if params[:customer].present?
            params.require(:customer).permit(:name, :phone, :email, :notes, :active)
          else
            params.permit(:name, :phone, :email, :notes, :active)
          end
        end
      end
    end
  end
end


