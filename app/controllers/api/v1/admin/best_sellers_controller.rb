module Api
  module V1
    module Admin
      class BestSellersController < BaseController
        before_action :set_best_seller, only: [:show, :update, :destroy, :toggle_pin, :toggle_highlight, :upload_images, :delete_image]

        def index
          best_sellers = BestSeller.ordered.includes(:menu_item)
          render json: best_sellers.map { |bs| best_seller_json(bs) }
        end

        def show
          render json: best_seller_json(@best_seller)
        end

        def create
          best_seller = BestSeller.new(best_seller_params)

          if best_seller.save
            render json: best_seller_json(best_seller), status: :created
          else
            render json: { errors: best_seller.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if @best_seller.update(best_seller_params)
            render json: best_seller_json(@best_seller)
          else
            render json: { errors: @best_seller.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @best_seller.destroy
          head :no_content
        end

        def toggle_pin
          @best_seller.update(pinned: !@best_seller.pinned)
          render json: best_seller_json(@best_seller)
        end

        def toggle_highlight
          @best_seller.update(highlighted: !@best_seller.highlighted)
          render json: best_seller_json(@best_seller)
        end

        def upload_images
          if params[:images].present?
            params[:images].each do |image|
              @best_seller.images.attach(image)
            end
            render json: best_seller_json(@best_seller)
          else
            render json: { error: 'No images provided' }, status: :unprocessable_entity
          end
        end

        def delete_image
          image = @best_seller.images.find_by(id: params[:image_id])
          if image
            image.purge
            render json: best_seller_json(@best_seller)
          else
            render json: { error: 'Image not found' }, status: :not_found
          end
        end

        def reorder
          params[:positions].each do |item|
            BestSeller.find(item[:id]).update(position: item[:position])
          end
          render json: { message: 'Best sellers reordered successfully' }
        end

        private

        def set_best_seller
          @best_seller = BestSeller.find(params[:id])
        end

        def best_seller_params
          params.permit(:menu_item_id, :title, :content, :image_url, :pinned, :highlighted, :position, :active)
        end

        def best_seller_json(bs)
          json = bs.as_json(
            methods: [:images_urls, :thumbnail_url],
            include: { menu_item: { only: [:id, :name, :price, :image_url, :images_urls, :thumbnail_url] } }
          )
          # Thêm trường images: [{id, url}] để FE dùng cho gallery/xoá ảnh
          json['images'] = bs.images.map do |img|
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
