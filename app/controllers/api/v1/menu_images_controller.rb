module Api
  module V1
    class MenuImagesController < ApplicationController
      def index
        menu_images = MenuImage.active.ordered.with_attached_image
        render json: menu_images.map { |img| menu_image_json(img) }
      end

      private

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
