module Api
  module V1
    module Admin
      class DailySpecialsController < BaseController
        before_action :set_daily_special, only: [:show, :update, :destroy, :toggle_pin, :toggle_highlight, :upload_images, :delete_image]

        def index
          daily_specials = DailySpecial.ordered.includes(:menu_item)
          
          if params[:date].present?
            daily_specials = daily_specials.where(special_date: params[:date])
          end

          render json: daily_specials.map { |ds| daily_special_json(ds) }
        end

        def show
          render json: daily_special_json(@daily_special)
        end

        def create
          daily_special = DailySpecial.new(daily_special_params)

          if daily_special.save
            render json: daily_special_json(daily_special), status: :created
          else
            render json: { errors: daily_special.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if @daily_special.update(daily_special_params)
            render json: daily_special_json(@daily_special)
          else
            render json: { errors: @daily_special.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @daily_special.destroy
          head :no_content
        end

        def toggle_pin
          @daily_special.update(pinned: !@daily_special.pinned)
          render json: daily_special_json(@daily_special)
        end

        def toggle_highlight
          @daily_special.update(highlighted: !@daily_special.highlighted)
          render json: daily_special_json(@daily_special)
        end

        def upload_images
          if params[:images].present?
            params[:images].each do |image|
              @daily_special.images.attach(image)
            end
            render json: daily_special_json(@daily_special)
          else
            render json: { error: 'No images provided' }, status: :unprocessable_entity
          end
        end

        def delete_image
          image = @daily_special.images.find_by(id: params[:image_id])
          if image
            image.purge
            render json: daily_special_json(@daily_special)
          else
            render json: { error: 'Image not found' }, status: :not_found
          end
        end

        private

        def set_daily_special
          @daily_special = DailySpecial.find(params[:id])
        end

        def daily_special_params
          params.permit(:menu_item_id, :title, :content, :image_url, :special_date, :pinned, :highlighted, :active)
        end

        def daily_special_json(ds)
          json = ds.as_json(
            methods: [:images_urls, :thumbnail_url],
            include: { menu_item: { only: [:id, :name, :price, :image_url, :images_urls, :thumbnail_url] } }
          )
          # Thêm trường images: [{id, url}] để FE dùng cho gallery/xoá ảnh
          json['images'] = ds.images.map do |img|
            {
              id: img.id,
              url: Rails.application.routes.url_helpers.rails_blob_url(img, only_path: true)
            }
          end
          json
        end
      end
    end
  end
end
