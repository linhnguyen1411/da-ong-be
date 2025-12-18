module Api
  module V1
    class RoomsController < ApplicationController
      def index
        rooms = Room.active.ordered.includes(:room_images, :bookings)

        # Build room data with booking status for the requested date
        booked_room_ids = []
        
        if params[:date].present?
          date = Date.parse(params[:date])
          time = params[:time].present? ? Time.parse(params[:time]) : nil

          rooms.each do |room|
            # Check for CONFIRMED bookings on the same date only
            conflicting_bookings = room.bookings
              .where(booking_date: date)
              .where(status: 'confirmed')
            
            # If time is provided, check for time overlap (± 2 hours)
            if time.present?
              conflicting_bookings = conflicting_bookings.select do |booking|
                booking_time = booking.booking_time
                time_diff = (booking_time.hour * 60 + booking_time.min) - (time.hour * 60 + time.min)
                time_diff.abs <= 120 # 2 hours in minutes
              end
            end

            booked_room_ids << room.id if conflicting_bookings.any?
          end
        end

        # Return ALL rooms with booked_for_date flag
        render json: rooms.map { |room|
          room.as_json(
            only: [:id, :name, :description, :capacity, :has_sound_system, :has_projector, :has_karaoke, :price_per_hour, :status, :position, :room_type],
            methods: [:images_urls, :thumbnail_url],
            include: { room_images: { only: [:id, :image_url, :caption] } }
          ).merge(booked_for_date: booked_room_ids.include?(room.id))
        }
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
