module Api
  module V1
    class MenuItemsController < ApplicationController
      def index
        menu_items = MenuItem.active.ordered.includes(:category).with_attached_images
        
        if params[:category_id].present?
          menu_items = menu_items.where(category_id: params[:category_id])
        end

        render json: menu_items.map { |item| menu_item_json(item) }
      end

      def show
        menu_item = MenuItem.find(params[:id])
        render json: menu_item_json(menu_item)
      end

      private

      def menu_item_json(item)
        json = item.as_json(include: { category: { only: [:id, :name] } })
        
        # Đảm bảo unit được serialize đúng (enum)
        json['unit'] = item.unit
        
        # Trả về mảng images_urls
        json['images_urls'] = item.images.attached? ? 
          item.images.map { |img| rails_blob_url(img, only_path: true) } : []
        
        # Thumbnail (ảnh đầu tiên hoặc fallback)
        json['thumbnail_url'] = item.images.attached? ? 
          rails_blob_url(item.images.first, only_path: true) : item.image_url
        
        json
      end
    end
  end
end
