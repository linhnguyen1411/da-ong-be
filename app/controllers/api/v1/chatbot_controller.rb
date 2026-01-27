module Api
  module V1
    class ChatbotController < ApplicationController
      # POST /api/v1/chat/respond
      # body: { message: string, context?: { date?:, time?:, party_size?: } }
      def respond
        message = params[:message].to_s
        context = params[:context].is_a?(Hash) ? params[:context] : {}

        result = Chatbot::Responder.call(message: message, context: context)
        render json: result
      rescue StandardError => e
        Rails.logger.error "Chatbot error: #{e.message}"
        render json: { intent: 'error', reply: 'Dạ hệ thống đang bận, anh/chị thử lại giúp em sau ít phút ạ.' }, status: :ok
      end
    end
  end
end


