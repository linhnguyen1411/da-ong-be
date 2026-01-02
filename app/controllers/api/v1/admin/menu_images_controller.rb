module Api
  module V1
    module Admin
      class MenuImagesController < BaseController
        def index
          menu_images = MenuImage.ordered.with_attached_image
          render json: menu_images.map { |img| menu_image_json(img) }
        end

        def create
          menu_image = MenuImage.new(menu_image_params)

          if params[:image].present?
            menu_image.image.attach(params[:image])
          end

          if menu_image.save
            render json: menu_image_json(menu_image), status: :created
          else
            render json: { errors: menu_image.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          menu_image = MenuImage.find(params[:id])

          if params[:image].present?
            menu_image.image.purge if menu_image.image.attached?
            menu_image.image.attach(params[:image])
          end

          if menu_image.update(menu_image_params.except(:image))
            render json: menu_image_json(menu_image)
          else
            render json: { errors: menu_image.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          menu_image = MenuImage.find(params[:id])
          menu_image.destroy
          head :no_content
        end

        def reorder
          params[:positions].each do |item|
            MenuImage.find(item[:id]).update(position: item[:position])
          end
          render json: { message: 'Menu images reordered successfully' }
        end

        private

        def menu_image_params
          params.permit(:position, :active, :image)
        end

        def menu_image_json(image)
          {
            id: image.id,
            image_url: image.image_url ? rails_blob_url(image.image, only_path: true) : nil,
            position: image.position,
            active: image.active
          }
        end
      end
    end
  end
end
