module Api
  module V1
    module Admin
      class ChatbotFaqsController < BaseController
        before_action :set_faq, only: [:show, :update, :destroy]

        # GET /api/v1/admin/chatbot_faqs
        def index
          faqs = ChatbotFaq.all.ordered
          faqs = faqs.where(locale: params[:locale]) if params[:locale].present?
          faqs = faqs.where(active: ActiveModel::Type::Boolean.new.cast(params[:active])) if params[:active].present?
          render json: faqs
        end

        # GET /api/v1/admin/chatbot_faqs/:id
        def show
          render json: @faq
        end

        # POST /api/v1/admin/chatbot_faqs
        def create
          faq = ChatbotFaq.new(faq_params)
          if faq.save
            render json: faq, status: :created
          else
            render json: { errors: faq.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # PATCH /api/v1/admin/chatbot_faqs/:id
        def update
          if @faq.update(faq_params)
            render json: @faq
          else
            render json: { errors: @faq.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/admin/chatbot_faqs/:id
        def destroy
          @faq.destroy
          head :no_content
        end

        private

        def set_faq
          @faq = ChatbotFaq.find(params[:id])
        end

        def faq_params
          if params[:chatbot_faq].present?
            params.require(:chatbot_faq).permit(:title, :answer, :active, :priority, :locale, patterns: [])
          else
            params.permit(:title, :answer, :active, :priority, :locale, patterns: [])
          end
        end
      end
    end
  end
end


