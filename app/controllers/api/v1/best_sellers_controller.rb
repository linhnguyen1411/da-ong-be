module Api
  module V1
    class BestSellersController < ApplicationController
      def index
        best_sellers = BestSeller.active.ordered.includes(menu_item: { images_attachments: :blob })
        render json: best_sellers.map { |bs| best_seller_json(bs) }
      end

      def show
        best_seller = BestSeller.find(params[:id])
        render json: best_seller_json(best_seller)
      end

      private

      def best_seller_json(bs)
        json = bs.as_json(methods: [:images_urls, :thumbnail_url])
        
        # Add menu_item info if exists
        if bs.menu_item.present?
          item = bs.menu_item
          json['menu_item'] = {
            id: item.id,
            name: item.name,
            price: item.price,
            thumbnail_url: item.images.attached? ? rails_blob_url(item.images.first, only_path: true) : item.image_url,
            images_urls: item.images.attached? ? item.images.map { |img| rails_blob_url(img, only_path: true) } : []
          }
        end
        
        json
      end
    end
  end
end
