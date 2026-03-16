# frozen_string_literal: true

module Api
  module V1
    class PromotionsController < ApplicationController
      # GET /api/v1/promotions
      def index
        promotions = Promotion.active.ordered
        render json: promotions
      end

      # GET /api/v1/promotions/:id
      def show
        promotion = Promotion.active.find(params[:id])
        render json: promotion
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end
    end
  end
end
