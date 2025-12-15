module Api
  module V1
    module Admin
      class MenuItemsController < BaseController
        before_action :set_menu_item, only: [:show, :update, :destroy, :upload_images, :delete_image]

        def index
          menu_items = MenuItem.ordered.includes(:category).with_attached_images
          
          if params[:category_id].present?
            menu_items = menu_items.where(category_id: params[:category_id])
          end

          render json: menu_items.map { |item| menu_item_json(item) }
        end

        def show
          render json: menu_item_json(@menu_item)
        end

        def create
          menu_item = MenuItem.new(menu_item_params)

          # Attach images if provided (support multiple)
          if params[:images].present?
            Array(params[:images]).each do |image|
              menu_item.images.attach(image)
            end
          end

          if menu_item.save
            render json: menu_item_json(menu_item), status: :created
          else
            render json: { errors: menu_item.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          # Attach new images if provided (append to existing)
          if params[:images].present?
            Array(params[:images]).each do |image|
              @menu_item.images.attach(image)
            end
          end

          if @menu_item.update(menu_item_params)
            render json: menu_item_json(@menu_item)
          else
            render json: { errors: @menu_item.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @menu_item.images.purge if @menu_item.images.attached?
          @menu_item.destroy
          head :no_content
        end

        # POST /api/v1/admin/menu_items/:id/upload_images
        def upload_images
          unless params[:images].present?
            render json: { error: 'No images uploaded' }, status: :bad_request
            return
          end

          Array(params[:images]).each do |image|
            @menu_item.images.attach(image)
          end
          
          if @menu_item.images.attached?
            render json: { 
              images_urls: @menu_item.images.map { |img| rails_blob_url(img, only_path: true) },
              message: 'Images uploaded successfully' 
            }
          else
            render json: { error: 'Failed to upload images' }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/admin/menu_items/:id/delete_image/:image_id
        def delete_image
          attachment = @menu_item.images.attachments.find_by(id: params[:image_id])
          if attachment
            attachment.purge
            render json: { 
              images: @menu_item.images.attachments.reload.map { |att| { id: att.id, url: rails_blob_url(att.blob, only_path: true) } },
              message: 'Image deleted successfully' 
            }
          else
            render json: { error: 'Image not found' }, status: :not_found
          end
        end

        def reorder
          params[:positions].each do |item|
            MenuItem.find(item[:id]).update(position: item[:position])
          end
          render json: { message: 'Menu items reordered successfully' }
        end

        private

        def set_menu_item
          @menu_item = MenuItem.find(params[:id])
        end

        def menu_item_params
          params.permit(:category_id, :name, :description, :price, :image_url, :active, :position)
        end

        def menu_item_json(item)
          json = item.as_json(include: { category: { only: [:id, :name] } })
          
          # Trả về mảng tất cả ảnh
          json['images_urls'] = item.images.attached? ? 
            item.images.map { |img| rails_blob_url(img, only_path: true) } : []
          
          # Thumbnail (ảnh đầu tiên)
          json['thumbnail_url'] = item.images.attached? ? 
            rails_blob_url(item.images.first, only_path: true) : item.image_url
          
          # Thêm image IDs để cho phép xóa từng ảnh (dùng attachment id)
          json['images'] = item.images.attached? ?
            item.images.attachments.map { |att| { id: att.id, url: rails_blob_url(att.blob, only_path: true) } } : []
          
          json
        end
      end
    end
  end
end
