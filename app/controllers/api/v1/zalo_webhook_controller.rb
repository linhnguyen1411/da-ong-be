module Api
  module V1
    class ZaloWebhookController < ApplicationController

      def message
        # Verify the request is from Zalo (you should implement signature verification)
        # For now, just log the user_id

        event_name = params[:event_name]
        Rails.logger.info "Zalo webhook event: #{event_name}"

        if event_name == 'user_send_text' || event_name == 'user_send_text_v2'
          user_id = params.dig(:sender, :id)
          message = params.dig(:message, :text)

          Rails.logger.info "Zalo message from user #{user_id}: #{message}"

          # You can store this user_id in database or env
          # For admin, check if message contains a specific keyword

          if message && message.downcase.include?('admin')
            Rails.logger.info "Admin user_id: #{user_id}"
            # You can update ENV or database here
          end
        elsif event_name == 'oa_send_text'
          # OA sending message - just log
          Rails.logger.info "OA sent message to user #{params.dig(:recipient, :id)}"
        end

        render json: { message: 'OK' }, status: :ok
      end

      def followers
        followers = ZaloService.get_followers
        render json: { followers: followers }, status: :ok
      end
    end
  end
end
