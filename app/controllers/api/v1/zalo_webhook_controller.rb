module Api
  module V1
    class ZaloWebhookController < ApplicationController

      def message
        # Log all incoming webhook data for debugging
        Rails.logger.info "=== ZALO WEBHOOK RECEIVED ==="
        Rails.logger.info "Full params: #{params.inspect}"
        Rails.logger.info "Event name: #{params[:event_name]}"
        Rails.logger.info "All parameters:"
        params.each do |key, value|
          Rails.logger.info "  #{key}: #{value.inspect}"
        end
        Rails.logger.info "=== END WEBHOOK ==="

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
        elsif event_name == 'follow'
          follower_id = params.dig(:follower, :id)
          Rails.logger.info "User followed OA: #{follower_id}"
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
