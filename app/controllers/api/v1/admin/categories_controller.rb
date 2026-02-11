module Api
  module V1
    module Admin
      class CategoriesController < BaseController
        before_action -> { require_roles!('super_admin', 'admin') }
        before_action :set_category, only: [:show, :update, :destroy]

        def index
          categories = Category.ordered
          render json: categories.as_json(include: { menu_items: { only: [:id, :name] } })
        end

        def show
          render json: @category.as_json(include: :menu_items)
        end

        def create
          category = Category.new(category_params)

          if category.save
            render json: category, status: :created
          else
            render json: { errors: category.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if @category.update(category_params)
            render json: @category
          else
            render json: { errors: @category.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @category.destroy
          head :no_content
        end

        def reorder
          params[:positions].each do |item|
            Category.find(item[:id]).update(position: item[:position])
          end
          render json: { message: 'Categories reordered successfully' }
        end

        private

        def set_category
          @category = Category.find(params[:id])
        end

        def category_params
          # Support both wrapped (category: {...}) and unwrapped ({...}) params
          if params[:category].present?
            params.require(:category).permit(:name, :description, :position, :active)
          else
            params.permit(:name, :description, :position, :active)
          end
        end
      end
    end
  end
end
