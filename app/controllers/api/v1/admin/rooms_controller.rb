module Api
  module V1
    module Admin
      class RoomsController < BaseController
        before_action :set_room, only: [:show, :update, :destroy, :update_status, :upload_images, :delete_image]

        def index
          rooms = Room.ordered
          render json: rooms.map { |room| room_json(room) }
        end

        def show
          render json: room_json(@room)
        end

        def create
          room = Room.new(room_params)

          if room.save
            render json: room_json(room), status: :created
          else
            render json: { errors: room.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if @room.update(room_params)
            render json: room_json(@room)
          else
            render json: { errors: @room.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @room.destroy
          head :no_content
        end

        def update_status
          if @room.update(status: params[:status])
            render json: room_json(@room)
          else
            render json: { errors: @room.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def upload_images
          if params[:images].present?
            params[:images].each do |image|
              @room.images.attach(image)
            end
          end
          render json: room_json(@room)
        end

        def delete_image
          image = @room.images.find { |img| img.id == params[:image_id].to_i }
          if image
            image.purge
            render json: room_json(@room)
          else
            render json: { error: 'Image not found' }, status: :not_found
          end
        end

        def reorder
          params[:positions].each do |item|
            Room.find(item[:id]).update(position: item[:position])
          end
          render json: { message: 'Rooms reordered successfully' }
        end

        def stats
          render json: {
            total: Room.count,
            available: Room.available.count,
            occupied: Room.where(status: 'occupied').count,
            maintenance: Room.where(status: 'maintenance').count
          }
        end

        private

        def set_room
          @room = Room.find(params[:id])
        end

        def room_params
          params.permit(
            :name, :description, :capacity, :has_sound_system, :has_projector, 
            :has_karaoke, :price_per_hour, :status, :position, :active, :room_type
          )
        end

        def room_json(room)
          room.as_json(methods: [:images_urls, :thumbnail_url]).merge(
            images: room.images.map { |img| { id: img.id, url: Rails.application.routes.url_helpers.url_for(img) } }
          )
        end
      end
    end
  end
end
