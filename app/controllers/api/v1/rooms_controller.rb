module Api
  module V1
    class RoomsController < ApplicationController
      def index
        rooms = Room.active.ordered.includes(:room_images)

        # Filter by availability if date and time are provided
        if params[:date].present? && params[:time].present?
          date = Date.parse(params[:date])
          time = Time.parse(params[:time])

          # Get rooms that don't have conflicting bookings
          available_room_ids = []
          rooms.each do |room|
            # Check for bookings on the same date with overlapping time
            conflicting_bookings = room.bookings
              .where(booking_date: date)
              .where(status: ['pending', 'confirmed'])
              .select do |booking|
                booking_time = booking.booking_time
                # Check if booking time overlaps with requested time ± 2 hours
                time_diff = (booking_time.hour * 60 + booking_time.min) - (time.hour * 60 + time.min)
                time_diff.abs <= 120 # 2 hours in minutes
              end

            available_room_ids << room.id if conflicting_bookings.empty?
          end

          rooms = rooms.where(id: available_room_ids)
        end

        render json: rooms.as_json(
          only: [:id, :name, :description, :capacity, :has_sound_system, :has_projector, :has_karaoke, :price_per_hour, :status, :position, :room_type],
          methods: [:images_urls, :thumbnail_url],
          include: { room_images: { only: [:id, :image_url, :caption] } }
        )
      end

      def show
        room = Room.find(params[:id])
        render json: room.as_json(
          only: [:id, :name, :description, :capacity, :has_sound_system, :has_projector, :has_karaoke, :price_per_hour, :status, :position, :room_type],
          methods: [:images_urls, :thumbnail_url],
          include: :room_images
        )
      end
    end
  end
end
