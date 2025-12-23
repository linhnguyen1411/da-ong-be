module Api
  module V1
    class BookingsController < ApplicationController
      def create
        # Validate menu items exist before creating booking
        if params[:booking_items_attributes].present?
          invalid_items = []
          params[:booking_items_attributes].each do |item|
            unless MenuItem.exists?(id: item[:menu_item_id])
              invalid_items << "Menu item ID #{item[:menu_item_id]} không tồn tại"
            end
          end
          
          if invalid_items.any?
            render json: { errors: invalid_items }, status: :unprocessable_entity
            return
          end
        end

        booking = Booking.new(booking_params)

        if booking.save
          # Send notification to admin via Zalo
          ZaloService.send_admin_notification(booking)

          render json: { 
            message: 'Đặt bàn thành công', 
            booking: booking.as_json(include: { booking_items: { include: :menu_item } })
          }, status: :created
        else
          render json: { errors: booking.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def check_availability
        room = Room.find(params[:room_id])
        date = Date.parse(params[:date])
        time = Time.parse(params[:time])

        existing_bookings = room.bookings
          .where(booking_date: date)
          .where(status: ['pending', 'confirmed'])
          .where('booking_time BETWEEN ? AND ?', time - 2.hours, time + 2.hours)

        render json: { 
          available: existing_bookings.empty?,
          existing_bookings_count: existing_bookings.count
        }
      end

      private

      def booking_params
        params.permit(
          :room_id, :customer_name, :customer_phone, :customer_email,
          :party_size, :booking_date, :booking_time, :duration_hours, :notes,
          booking_items_attributes: [:menu_item_id, :quantity, :notes]
        )
      end
    end
  end
end
