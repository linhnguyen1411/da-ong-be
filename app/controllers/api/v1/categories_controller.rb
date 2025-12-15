module Api
  module V1
    class CategoriesController < ApplicationController
      def index
        categories = Category.active.ordered.includes(:menu_items)
        render json: categories.as_json(include: { menu_items: { only: [:id, :name, :price, :image_url] } })
      end

      def show
        category = Category.find(params[:id])
        render json: category.as_json(include: :menu_items)
      end
    end
  end
end
