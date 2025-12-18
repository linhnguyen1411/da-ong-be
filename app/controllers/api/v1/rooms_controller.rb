module Api
  module V1
    class RoomsController < ApplicationController
      def index
        rooms = Room.active.available.ordered.includes(:room_images)

        # Filter by availability if date and time are provided
        if params[:date].present? && params[:time].present?
          date = Date.parse(params[:date])
          time = Time.parse(params[:time])

          # Get rooms that don't have conflicting bookings
          available_room_ids = rooms.map do |room|
            existing_bookings = room.bookings
              .where(booking_date: date)
              .where(status: ['pending', 'confirmed'])
              .where('booking_time BETWEEN ? AND ?', time - 2.hours, time + 2.hours)

            room.id if existing_bookings.empty?
          end.compact

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
