module Api
  module V1
    class DailySpecialsController < ApplicationController
      def index
        daily_specials = DailySpecial.active.ordered.includes(menu_item: { images_attachments: :blob })
        
        if params[:today].present?
          daily_specials = daily_specials.today
        end

        render json: daily_specials.map { |ds| daily_special_json(ds) }
      end

      def show
        daily_special = DailySpecial.find(params[:id])
        render json: daily_special_json(daily_special)
      end

      private

      def daily_special_json(ds)
        json = ds.as_json(methods: [:images_urls, :thumbnail_url])
        
        # Add menu_item info if exists
        if ds.menu_item.present?
          item = ds.menu_item
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
