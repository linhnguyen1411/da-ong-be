# frozen_string_literal: true

module Api
  module V1
    module Admin
      class RecruitmentsController < BaseController
        before_action :set_recruitment, only: [:show, :update, :destroy]

        # GET /api/v1/admin/recruitments
        def index
          recruitments = Recruitment.ordered
          render json: recruitments
        end

        # GET /api/v1/admin/recruitments/:id
        def show
          render json: @recruitment
        end

        # POST /api/v1/admin/recruitments
        def create
          recruitment = Recruitment.new(recruitment_params)
          if recruitment.save
            render json: recruitment, status: :created
          else
            render json: { errors: recruitment.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # PATCH /api/v1/admin/recruitments/:id
        def update
          if @recruitment.update(recruitment_params)
            render json: @recruitment
          else
            render json: { errors: @recruitment.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/admin/recruitments/:id
        def destroy
          @recruitment.destroy
          head :no_content
        end

        private

        def set_recruitment
          @recruitment = Recruitment.find(params[:id])
        end

        def recruitment_params
          if params[:recruitment].present?
            params.require(:recruitment).permit(:title, :content, :department, :position, :active)
          else
            params.permit(:title, :content, :department, :position, :active)
          end
        end
      end
    end
  end
end
