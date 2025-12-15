module Api
  module V1
    class RoomsController < ApplicationController
      def index
        rooms = Room.active.available.ordered.includes(:room_images)
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
