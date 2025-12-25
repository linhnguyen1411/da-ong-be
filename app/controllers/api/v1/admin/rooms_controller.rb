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
          # occupied status is now calculated from room_schedules, not stored in room.status
          render json: {
            total: Room.count,
            available: Room.available.count,
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
          host = ENV['APP_HOST'] || 'nhahangdavaong.com'
          room.as_json(methods: [:images_urls, :images_urls_medium, :images_urls_thumb, :thumbnail_url, :thumbnail_url_medium, :thumbnail_url_thumb]).merge(
            images: room.images.map { |img| 
              begin
                original_url = Rails.application.routes.url_helpers.rails_storage_proxy_url(img, host: host, protocol: 'https')
                { 
                  id: img.id, 
                  url: original_url,
                  url_medium: room.variant_url(img, resize_to_limit: [800, 600]) || original_url,
                  url_thumb: room.variant_url(img, resize_to_limit: [400, 300]) || original_url
                }
              rescue => e
                Rails.logger.error "Error processing image #{img.id}: #{e.message}"
                original_url = Rails.application.routes.url_helpers.rails_storage_proxy_url(img, host: host, protocol: 'https')
                {
                  id: img.id,
                  url: original_url,
                  url_medium: original_url,
                  url_thumb: original_url
                }
              end
            }
          )
        end
      end
    end
  end
end
