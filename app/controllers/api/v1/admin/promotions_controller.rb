# frozen_string_literal: true

module Api
  module V1
    module Admin
      class PromotionsController < BaseController
        before_action :set_promotion, only: [:show, :update, :destroy]

        # GET /api/v1/admin/promotions
        def index
          promotions = Promotion.ordered
          render json: promotions
        end

        # GET /api/v1/admin/promotions/:id
        def show
          render json: @promotion
        end

        # POST /api/v1/admin/promotions
        def create
          promotion = Promotion.new(promotion_params)
          if promotion.save
            render json: promotion, status: :created
          else
            render json: { errors: promotion.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # PATCH /api/v1/admin/promotions/:id
        def update
          if @promotion.update(promotion_params)
            render json: @promotion
          else
            render json: { errors: @promotion.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/admin/promotions/:id
        def destroy
          @promotion.destroy
          head :no_content
        end

        private

        def set_promotion
          @promotion = Promotion.find(params[:id])
        end

        def promotion_params
          if params[:promotion].present?
            params.require(:promotion).permit(:title, :content, :image_url, :highlighted, :position, :active, :start_at, :end_at)
          else
            params.permit(:title, :content, :image_url, :highlighted, :position, :active, :start_at, :end_at)
          end
        end
      end
    end
  end
end
