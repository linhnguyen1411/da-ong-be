# app/services/zalo_service.rb
# Zalo OA API Service with auto token refresh
# Documentation: https://developers.zalo.me/docs/official-account/bat-dau/xac-thuc-va-uy-quyen-cho-ung-dung-new

require 'httparty'
require 'base64'

class ZaloService
  ZALO_API_V3 = 'https://openapi.zalo.me/v3.0'
  ZALO_OAUTH_URL = 'https://oauth.zaloapp.com/v4/oa/access_token'
  
  # Access token expires in ~1 hour, refresh token expires in ~90 days
  ACCESS_TOKEN_BUFFER = 5.minutes # Refresh 5 mins before expiry
  
  class << self
    # ===============================
    # Token Management
    # ===============================
    
    def app_id
      ENV['ZALO_APP_ID']
    end

    def app_secret
      ENV['ZALO_APP_SECRET']
    end

    def access_token
      token_record = ZaloToken.current
      
      # If no token stored or refresh token expired, use ENV fallback
      if token_record.new_record? || token_record.refresh_token_expired?
        Rails.logger.warn "[ZALO] No valid token in DB, using ENV fallback"
        return ENV['ZALO_OA_ACCESS_TOKEN']
      end
      
      # If access token expired, refresh it
      if token_record.access_token_expired?
        Rails.logger.info "[ZALO] Access token expired, refreshing..."
        refresh_access_token(token_record)
      end
      
      token_record.access_token
    end

    # Refresh access token using refresh token
    def refresh_access_token(token_record = nil)
      token_record ||= ZaloToken.current
      
      return nil if token_record.new_record? || token_record.refresh_token.blank?
      
      # Build secret_key as Base64(app_id:app_secret)
      secret_key = Base64.strict_encode64("#{app_id}:#{app_secret}")
      
      response = HTTParty.post(
        ZALO_OAUTH_URL,
        headers: {
          'Content-Type' => 'application/x-www-form-urlencoded',
          'secret_key' => secret_key
        },
        body: {
          refresh_token: token_record.refresh_token,
          app_id: app_id,
          grant_type: 'refresh_token'
        }
      )
      
      Rails.logger.info "[ZALO] Refresh token response: #{response.code}"
      
      if response.code == 200
        data = JSON.parse(response.body)
        
        if data['access_token'].present?
          # Update tokens in database
          token_record.update!(
            access_token: data['access_token'],
            refresh_token: data['refresh_token'] || token_record.refresh_token,
            access_token_expires_at: Time.current + (data['expires_in'] || 3600).seconds - ACCESS_TOKEN_BUFFER
          )
          
          Rails.logger.info "[ZALO] Token refreshed successfully, expires at: #{token_record.access_token_expires_at}"
          return data['access_token']
        else
          Rails.logger.error "[ZALO] Refresh failed: #{data['error_description'] || data['message']}"
        end
      else
        Rails.logger.error "[ZALO] Refresh request failed: #{response.body}"
      end
      
      nil
    end

    # Initialize tokens (call this manually with initial tokens from API Explorer)
    def initialize_tokens(access_token:, refresh_token:, expires_in: 3600)
      token_record = ZaloToken.first_or_initialize
      token_record.update!(
        access_token: access_token,
        refresh_token: refresh_token,
        access_token_expires_at: Time.current + expires_in.seconds - ACCESS_TOKEN_BUFFER,
        refresh_token_expires_at: Time.current + 90.days # Refresh token valid ~90 days
      )
      
      Rails.logger.info "[ZALO] Tokens initialized successfully"
      token_record
    end

    # ===============================
    # Send message (v3.0 API)
    # ===============================
    def send_message(user_id, text)
      token = access_token
      unless token
        Rails.logger.error "[ZALO] No valid access token available"
        return false
      end

      response = HTTParty.post(
        "#{ZALO_API_V3}/oa/message/cs",
        headers: {
          'access_token' => token,
          'Content-Type' => 'application/json'
        },
        body: {
          recipient: { user_id: user_id },
          message: { text: text }
        }.to_json
      )
      
      log_response('send_message', response)
      
      # Handle token expired error
      if response.code == 401 || (response.parsed_response && response.parsed_response['error'] == -124)
        Rails.logger.warn "[ZALO] Token expired during request, refreshing and retrying..."
        refresh_access_token
        return send_message(user_id, text) # Retry once
      end
      
      response.success? && response.parsed_response['error'] == 0
    end

    # ===============================
    # Send admin notification
    # ===============================
    def send_admin_notification(booking)
      admin_user_id = ENV['ZALO_ADMIN_USER_IDS']
      return unless admin_user_id.present?

      room_info = booking.room ? "Phòng: #{booking.room.name}\n" : ""
      
      message = "🔔 CÓ ĐẶT BÀN MỚI!\n\n" \
                "👤 Khách hàng: #{booking.customer_name}\n" \
                "📞 SĐT: #{booking.customer_phone}\n" \
                "👥 Số khách: #{booking.party_size} người\n" \
                "📅 Ngày: #{booking.booking_date&.strftime('%d/%m/%Y')}\n" \
                "🕐 Giờ: #{booking.booking_time&.strftime('%H:%M')}\n" \
                "#{room_info}" \
                "📝 Ghi chú: #{booking.notes || 'Không có'}\n\n" \
                "Vui lòng xác nhận đơn đặt bàn!"

      send_message(admin_user_id, message)
    end

    # ===============================
    # Get followers list
    # ===============================
    def get_followers(offset = 0, count = 50)
      token = access_token
      return [] unless token

      response = HTTParty.get(
        "#{ZALO_API_V3}/oa/getfollowers",
        headers: { 'access_token' => token },
        query: { data: { offset: offset, count: count }.to_json }
      )
      
      log_response('get_followers', response)
      
      if response.success? && response.parsed_response['error'] == 0
        response.parsed_response['data']['followers'] || []
      else
        []
      end
    end

    # ===============================
    # Get user info
    # ===============================
    def get_user_info(user_id)
      token = access_token
      return nil unless token

      response = HTTParty.get(
        "#{ZALO_API_V3}/oa/getprofile",
        headers: { 'access_token' => token },
        query: { data: { user_id: user_id }.to_json }
      )
      
      log_response('get_user_info', response)
      
      if response.success? && response.parsed_response['error'] == 0
        response.parsed_response['data']
      else
        nil
      end
    end

    private

    def log_response(action, response)
      parsed = response.parsed_response rescue response.body
      
      if response.success? && (parsed.is_a?(Hash) && parsed['error'] == 0)
        Rails.logger.info "[ZALO] #{action} success: #{parsed}"
      else
        Rails.logger.error "[ZALO] #{action} failed (#{response.code}): #{parsed}"
      end
    end
  end
end
