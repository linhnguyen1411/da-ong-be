# frozen_string_literal: true

module Api
  module V1
    class RecruitmentsController < ApplicationController
      # GET /api/v1/recruitments
      def index
        recruitments = Recruitment.active.ordered
        render json: recruitments
      end

      # GET /api/v1/recruitments/:id
      def show
        recruitment = Recruitment.active.find(params[:id])
        render json: recruitment
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end
    end
  end
end
