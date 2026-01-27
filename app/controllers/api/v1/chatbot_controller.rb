module Api
  module V1
    class ChatbotController < ApplicationController
      # POST /api/v1/chat/respond
      # body: { message: string, context?: { date?:, time?:, party_size?:, company_name?:, system_instruction?: } }
      def respond
        message = params[:message].to_s
        raw = params[:context].is_a?(Hash) ? params[:context] : {}

        # Whitelist + size guard (don't allow huge prompts from client)
        context = {}
        context['date'] = raw['date'] if raw['date'].present?
        context['time'] = raw['time'] if raw['time'].present?
        context['party_size'] = raw['party_size'] if raw['party_size'].present?
        context['company_name'] = raw['company_name'].to_s[0, 80] if raw['company_name'].present?
        context['system_instruction'] = raw['system_instruction'].to_s[0, 5000] if raw['system_instruction'].present?

        result = Chatbot::Responder.call(message: message, context: context)
        render json: result
      rescue StandardError => e
        Rails.logger.error "Chatbot error: #{e.message}"
        render json: { intent: 'error', reply: 'Dạ hệ thống đang bận, anh/chị thử lại giúp em sau ít phút ạ.' }, status: :ok
      end
    end
  end
end


