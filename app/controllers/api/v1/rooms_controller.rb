module Api
  module V1
    class RoomsController < ApplicationController
      def index
        rooms = Room.active.ordered.includes(:room_images, :bookings)

        # Build room data with booking status for the requested date
        room_bookings_map = {}
        
        if params[:date].present?
          date = Date.parse(params[:date])
          time = params[:time].present? ? Time.parse(params[:time]) : nil

          rooms.each do |room|
            # Check for CONFIRMED bookings on the same date only
            conflicting_bookings = room.bookings
              .where(booking_date: date)
              .where(status: 'confirmed')
              .order(booking_time: :asc)
            
            # If time is provided, check for time overlap (± 2 hours)
            if time.present?
              conflicting_bookings = conflicting_bookings.select do |booking|
                booking_time = booking.booking_time
                time_diff = (booking_time.hour * 60 + booking_time.min) - (time.hour * 60 + time.min)
                time_diff.abs <= 120 # 2 hours in minutes
              end
            end

            # Store booking info for this room
            if conflicting_bookings.any?
              room_bookings_map[room.id] = conflicting_bookings.map do |booking|
                {
                  id: booking.id,
                  customer_name: booking.customer_name,
                  booking_time: booking.booking_time.strftime('%H:%M'),
                  party_size: booking.party_size
                }
              end
            end
          end
        end

        # Return ALL rooms with booked_for_date flag and booking info
        render json: rooms.map { |room|
          bookings_info = room_bookings_map[room.id] || []
          room.as_json(
            only: [:id, :name, :description, :capacity, :has_sound_system, :has_projector, :has_karaoke, :price_per_hour, :status, :position, :room_type],
            methods: [:images_urls, :images_urls_medium, :images_urls_thumb, :thumbnail_url, :thumbnail_url_medium, :thumbnail_url_thumb],
            include: { room_images: { only: [:id, :image_url, :caption] } }
          ).merge(
            booked_for_date: bookings_info.any?,
            bookings: bookings_info
          )
        }
      end

      def show
        room = Room.find(params[:id])
        render json: room.as_json(
          only: [:id, :name, :description, :capacity, :has_sound_system, :has_projector, :has_karaoke, :price_per_hour, :status, :position, :room_type],
          methods: [:images_urls, :images_urls_medium, :images_urls_thumb, :thumbnail_url, :thumbnail_url_medium, :thumbnail_url_thumb],
          include: :room_images
        )
      end
    end
  end
end
