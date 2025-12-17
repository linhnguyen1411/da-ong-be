module Api
  module V1
    class ZaloWebhookController < ApplicationController
      skip_before_action :verify_authenticity_token

      def message
        # Verify the request is from Zalo (you should implement signature verification)
        # For now, just log the user_id

        if params[:event_name] == 'user_send_text'
          user_id = params.dig(:sender, :id)
          message = params.dig(:message, :text)

          Rails.logger.info "Zalo message from user #{user_id}: #{message}"

          # You can store this user_id in database or env
          # For admin, check if message contains a specific keyword

          if message.downcase.include?('admin')
            Rails.logger.info "Admin user_id: #{user_id}"
            # You can update ENV or database here
          end
        end

        render json: { message: 'OK' }, status: :ok
      end
    end
  end
end
