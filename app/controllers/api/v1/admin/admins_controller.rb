module Api
  module V1
    module Admin
      class AdminsController < BaseController
        before_action -> { require_roles!('super_admin', 'admin', 'manager') }
        before_action :set_admin, only: [:show, :update, :destroy]

        def index
          admins = ::Admin.order(created_at: :desc)
          admins = filter_for_current_role(admins)
          admins = admins.where.not(role: 'super_admin') if current_admin.effective_role != 'super_admin'
          render json: admins.as_json(only: [:id, :email, :name, :role, :active, :created_at])
        end

        def show
          return if forbidden_target?(@admin)
          render json: @admin.as_json(only: [:id, :email, :name, :role, :active, :created_at])
        end

        def create
          attrs = admin_params.to_h
          normalize_role!(attrs)
          return unless role_allowed_for_current_admin?(attrs[:role])

          admin = ::Admin.new(attrs)
          if admin.save
            render json: admin.as_json(only: [:id, :email, :name, :role, :active, :created_at]), status: :created
          else
            render json: { errors: admin.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          return if forbidden_target?(@admin)

          attrs = admin_params.to_h
          normalize_role!(attrs)
          if attrs.key?(:role)
            return unless role_allowed_for_current_admin?(attrs[:role])
          end

          # If password fields are blank, don't overwrite existing password
          if attrs[:password].blank?
            attrs.delete(:password)
            attrs.delete(:password_confirmation)
          end

          if @admin.update(attrs)
            render json: @admin.as_json(only: [:id, :email, :name, :role, :active, :created_at])
          else
            render json: { errors: @admin.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # "Delete" = deactivate by default to avoid losing audit trail.
        def destroy
          return if forbidden_target?(@admin)

          @admin.update!(active: false)
          render json: { message: 'Deactivated' }
        end

        private

        def set_admin
          @admin = ::Admin.find(params[:id])
        end

        def admin_params
          params.permit(:email, :name, :role, :active, :password, :password_confirmation)
        end

        def normalize_role!(attrs)
          attrs[:role] = attrs[:role].to_s.strip if attrs.key?(:role)
        end

        def filter_for_current_role(scope)
          if current_admin.effective_role == 'manager'
            # Manager can only see receptionist/staff accounts
            scope.where(role: ['receptionist', 'staff'])
          else
            scope
          end
        end

        def enforce_role_constraints!(new_role)
          # Deprecated: keep for backwards compatibility if referenced elsewhere
          role_allowed_for_current_admin?(new_role)
        end

        def role_allowed_for_current_admin?(new_role)
          return true if new_role.blank?

          if current_admin.effective_role == 'manager'
            unless %w[receptionist staff].include?(new_role)
              render json: { error: 'Forbidden' }, status: :forbidden
              return false
            end
          end

          true
        end

        def forbidden_target?(target_admin)
          # Managers cannot touch admin/manager/super_admin accounts, and cannot edit themselves here.
          if current_admin.effective_role == 'manager'
            if target_admin.id == current_admin.id
              render json: { error: 'Forbidden' }, status: :forbidden
              return true
            end
            unless %w[receptionist staff].include?(target_admin.role)
              render json: { error: 'Forbidden' }, status: :forbidden
              return true
            end
          end

          # Prevent non-super-admin from changing/deactivating super_admin accounts
          if target_admin.role == 'super_admin' && current_admin.effective_role != 'super_admin'
            render json: { error: 'Forbidden' }, status: :forbidden
            return true
          end

          false
        end
      end
    end
  end
end


