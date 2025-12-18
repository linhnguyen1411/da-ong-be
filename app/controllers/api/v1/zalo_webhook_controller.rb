module Api
  module V1
    class ZaloWebhookController < ApplicationController

      def verify
        # Webhook verification for Zalo OA
        challenge = params[:challenge]
        if challenge.present?
          Rails.logger.info "Zalo webhook verification challenge: #{challenge}"
          render json: { challenge: challenge }, status: :ok
        else
          render json: { error: 'Missing challenge parameter' }, status: :bad_request
        end
      end

      def message
        # Verify webhook signature if present
        unless verify_signature
          Rails.logger.warn "Invalid webhook signature"
          render json: { error: 'Invalid signature' }, status: :unauthorized
          return
        end

        # Log all incoming webhook data for debugging
        Rails.logger.info "=== ZALO WEBHOOK RECEIVED ==="
        Rails.logger.info "Event name: #{params[:event_name]}"
        Rails.logger.info "Timestamp: #{params[:timestamp]}"
        Rails.logger.info "App ID: #{params[:app_id]}"
        Rails.logger.info "Full params: #{params.inspect}"
        Rails.logger.info "=== END WEBHOOK ==="

        event_name = params[:event_name]
        Rails.logger.info "Processing Zalo webhook event: #{event_name}"

        case event_name
        when 'user_send_text', 'user_send_text_v2'
          handle_user_send_text
        when 'user_send_image'
          handle_user_send_image
        when 'user_send_location'
          handle_user_send_location
        when 'user_send_sticker'
          handle_user_send_sticker
        when 'user_send_file'
          handle_user_send_file
        when 'user_send_link'
          handle_user_send_link
        when 'oa_send_text'
          handle_oa_send_text
        when 'oa_send_image'
          handle_oa_send_image
        when 'follow'
          handle_follow
        when 'unfollow'
          handle_unfollow
        when 'user_received_message'
          handle_user_received_message
        when 'user_seen_message'
          handle_user_seen_message
        when 'user_send_phone'
          handle_user_send_phone
        when 'user_send_address'
          handle_user_send_address
        else
          Rails.logger.info "Unhandled event type: #{event_name}"
          handle_unknown_event(event_name)
        end

        render json: { message: 'OK' }, status: :ok
      rescue => e
        Rails.logger.error "Error processing Zalo webhook: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: { error: 'Internal server error' }, status: :internal_server_error
      end

      private

      def verify_signature
        # Zalo webhook signature verification
        signature = request.headers['X-Zalo-Signature']
        return true unless signature.present? # Skip verification if no signature

        secret = ENV['ZALO_WEBHOOK_SECRET']
        return false unless secret.present?

        # Create signature from request body
        body = request.raw_post
        expected_signature = OpenSSL::HMAC.hexdigest('sha256', secret, body)

        # Compare signatures (case-insensitive)
        signature.downcase == expected_signature.downcase
      end

      def handle_user_send_text
        user_id = params.dig(:sender, :id)
        message = params.dig(:message, :text)
        message_id = params.dig(:message, :msg_id)

        Rails.logger.info "User #{user_id} sent text message: #{message} (ID: #{message_id})"

        # Store user interaction if needed
        # You can add database storage here for user messages

        # Auto-reply or forward to admin if needed
        if message && message.downcase.include?('help')
          # Could send automated help message
          Rails.logger.info "User requested help"
        end
      end

      def handle_user_send_image
        user_id = params.dig(:sender, :id)
        image_url = params.dig(:message, :url)
        message_id = params.dig(:message, :msg_id)

        Rails.logger.info "User #{user_id} sent image: #{image_url} (ID: #{message_id})"
      end

      def handle_user_send_location
        user_id = params.dig(:sender, :id)
        latitude = params.dig(:message, :coordinates, :latitude)
        longitude = params.dig(:message, :coordinates, :longitude)
        message_id = params.dig(:message, :msg_id)

        Rails.logger.info "User #{user_id} sent location: #{latitude}, #{longitude} (ID: #{message_id})"
      end

      def handle_user_send_sticker
        user_id = params.dig(:sender, :id)
        sticker_id = params.dig(:message, :sticker_id)
        message_id = params.dig(:message, :msg_id)

        Rails.logger.info "User #{user_id} sent sticker: #{sticker_id} (ID: #{message_id})"
      end

      def handle_oa_send_text
        recipient_id = params.dig(:recipient, :id)
        message = params.dig(:message, :text)
        message_id = params.dig(:message, :msg_id)

        Rails.logger.info "OA sent text message to user #{recipient_id}: #{message} (ID: #{message_id})"
      end

      def handle_follow
        follower_id = params.dig(:follower, :id)
        follower_info = params.dig(:follower)

        Rails.logger.info "User followed OA: #{follower_id}"
        Rails.logger.info "Follower info: #{follower_info.inspect}"

        # Store follower information
        # You can add database storage here for followers
      end

      def handle_unfollow
        follower_id = params.dig(:follower, :id)

        Rails.logger.info "User unfollowed OA: #{follower_id}"

        # Remove follower from database if needed
      end

      def handle_user_send_file
        user_id = params.dig(:sender, :id)
        file_url = params.dig(:message, :url)
        file_name = params.dig(:message, :name)
        message_id = params.dig(:message, :msg_id)

        Rails.logger.info "User #{user_id} sent file: #{file_name} (#{file_url}) (ID: #{message_id})"
      end

      def handle_user_send_link
        user_id = params.dig(:sender, :id)
        link_url = params.dig(:message, :url)
        link_title = params.dig(:message, :title)
        link_description = params.dig(:message, :description)
        message_id = params.dig(:message, :msg_id)

        Rails.logger.info "User #{user_id} sent link: #{link_title} - #{link_url} (ID: #{message_id})"
      end

      def handle_oa_send_image
        recipient_id = params.dig(:recipient, :id)
        image_url = params.dig(:message, :url)
        message_id = params.dig(:message, :msg_id)

        Rails.logger.info "OA sent image to user #{recipient_id}: #{image_url} (ID: #{message_id})"
      end

      def handle_user_seen_message
        user_id = params.dig(:sender, :id)
        message_id = params.dig(:message, :msg_id)

        Rails.logger.info "User #{user_id} seen message with ID: #{message_id}"
      end

      def handle_user_send_phone
        user_id = params.dig(:sender, :id)
        phone = params.dig(:message, :phone)
        message_id = params.dig(:message, :msg_id)

        Rails.logger.info "User #{user_id} shared phone: #{phone} (ID: #{message_id})"
      end

      def handle_user_send_address
        user_id = params.dig(:sender, :id)
        address = params.dig(:message, :address)
        latitude = params.dig(:message, :coordinates, :latitude)
        longitude = params.dig(:message, :coordinates, :longitude)
        message_id = params.dig(:message, :msg_id)

        Rails.logger.info "User #{user_id} shared address: #{address} (#{latitude}, #{longitude}) (ID: #{message_id})"
      end

      def handle_unknown_event(event_name)
        Rails.logger.info "Unknown event type received: #{event_name}"
        Rails.logger.info "Event data: #{params.except(:controller, :action).to_json}"
      end

      def followers
        followers = ZaloService.get_followers
        render json: { followers: followers }, status: :ok
      end
    end
  end
end
