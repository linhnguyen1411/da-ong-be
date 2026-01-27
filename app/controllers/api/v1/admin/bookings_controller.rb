module Api
  module V1
    module Admin
      class BookingsController < BaseController
        before_action :set_booking, only: [:show, :update, :destroy, :confirm, :cancel, :complete]

        def index
          bookings = Booking.recent.includes(:room, booking_items: :menu_item)

          # Filter by status
          bookings = bookings.where(status: params[:status]) if params[:status].present?

          # Filter by date
          if params[:date].present?
            bookings = bookings.where(booking_date: params[:date])
          elsif params[:start_date].present? && params[:end_date].present?
            bookings = bookings.where(booking_date: params[:start_date]..params[:end_date])
          end

          # Filter by room
          bookings = bookings.where(room_id: params[:room_id]) if params[:room_id].present?

          render json: bookings.as_json(
            include: { 
              room: { only: [:id, :name] },
              booking_items: { include: { menu_item: { only: [:id, :name, :price] } } }
            },
            methods: [:total_amount, :formatted_booking_time]
          ).map do |booking|
            booking['booking_time'] = booking['formatted_booking_time'] || booking['booking_time']
            booking.delete('formatted_booking_time')
            booking
          end
        end

        def show
          booking_json = @booking.as_json(
            include: { 
              room: { only: [:id, :name, :capacity] },
              booking_items: { include: :menu_item }
            },
            methods: [:total_amount, :formatted_booking_time]
          )
          booking_json['booking_time'] = booking_json['formatted_booking_time'] || booking_json['booking_time']
          booking_json.delete('formatted_booking_time')
          render json: booking_json
        end

        def update
          if @booking.update(booking_params)
            booking_json = @booking.as_json(
              include: { booking_items: { include: :menu_item } },
              methods: [:formatted_booking_time]
            )
            booking_json['booking_time'] = booking_json['formatted_booking_time'] || booking_json['booking_time']
            booking_json.delete('formatted_booking_time')
            render json: booking_json
          else
            render json: { errors: @booking.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @booking.destroy
          head :no_content
        end

        def confirm
          @booking.confirm!
          render json: @booking
        end

        def cancel
          @booking.cancel!
          render json: @booking
        end

        def complete
          @booking.complete!
          Loyalty::AccrueForBooking.call(@booking, admin: current_admin)
          render json: @booking
        end

        def today
          bookings = Booking.today.includes(:room, booking_items: :menu_item)
          render json: bookings.as_json(
            include: { room: { only: [:id, :name] } },
            methods: [:total_amount, :formatted_booking_time]
          ).map do |booking|
            booking['booking_time'] = booking['formatted_booking_time'] || booking['booking_time']
            booking.delete('formatted_booking_time')
            booking
          end
        end

        def upcoming
          bookings = Booking.upcoming.limit(20).includes(:room)
          render json: bookings.as_json(include: { room: { only: [:id, :name] } })
        end

        def stats
          render json: {
            total: Booking.count,
            pending: Booking.pending.count,
            confirmed: Booking.confirmed.count,
            cancelled: Booking.cancelled.count,
            completed: Booking.completed.count,
            today: Booking.today.count,
            today_pending: Booking.today.pending.count,
            today_confirmed: Booking.today.confirmed.count,
            this_week: Booking.where(booking_date: Date.current.beginning_of_week..Date.current.end_of_week).count,
            this_month: Booking.where(booking_date: Date.current.beginning_of_month..Date.current.end_of_month).count
          }
        end

        def dashboard
          render json: {
            stats: {
              total_bookings: Booking.count,
              pending: Booking.pending.count,
              confirmed: Booking.confirmed.count,
              today: Booking.today.count
            },
            today_bookings: Booking.today.includes(:room).as_json(
              include: { room: { only: [:id, :name] } },
              methods: [:formatted_booking_time]
            ).map do |booking|
              booking['booking_time'] = booking['formatted_booking_time'] || booking['booking_time']
              booking.delete('formatted_booking_time')
              booking
            end,
            upcoming_bookings: Booking.upcoming.limit(10).includes(:room).as_json(include: { room: { only: [:id, :name] } }),
            recent_contacts: Contact.unread.limit(5).as_json,
            room_status: Room.ordered.as_json(only: [:id, :name, :status, :capacity])
          }
        end

        private

        def set_booking
          @booking = Booking.find(params[:id])
        end

        def booking_params
          params.permit(
            :room_id, :customer_name, :customer_phone, :customer_email,
            :party_size, :booking_date, :booking_time, :duration_hours, :notes, :status,
            booking_items_attributes: [:id, :menu_item_id, :quantity, :notes, :_destroy]
          )
        end
      end
    end
  end
end
