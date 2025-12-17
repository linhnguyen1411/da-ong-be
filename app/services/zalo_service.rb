# app/services/zalo_service.rb
require 'httparty'

class ZaloService
  ZALO_API_BASE = 'https://openapi.zalo.me'
  ZALO_API_VERSION = 'v3.0'

  class << self
    def access_token
      ENV['ZALO_OA_ACCESS_TOKEN']
    end

    def oa_id
      ENV['ZALO_OA_ID']
    end

    # ===============================
    # Get Access Token (if needed)
    # ===============================
    def get_access_token
      return access_token if access_token.present?

      # Note: Programmatic token retrieval is not recommended
      # Use the hardcoded token from Zalo Developer Console instead
      Rails.logger.warn "[ZALO] No access token configured"
      nil
    end

    # ===============================
    # Send Message (Updated API)
    # ===============================
    def send_message(user_id, text)
      token = get_access_token
      return false unless token

      url = "#{ZALO_API_BASE}/#{ZALO_API_VERSION}/oa/message/cs"

      payload = {
        recipient: {
          user_id: user_id.to_s
        },
        message: {
          text: text.to_s
        }
      }

      response = HTTParty.post(
        url,
        headers: {
          'Content-Type' => 'application/json',
          'access_token' => token
        },
        body: payload.to_json,
        timeout: 30
      )

      log_response('send_message', response)

      if response.success?
        result = response.parsed_response
        if result['error'] == 0
          Rails.logger.info "[ZALO] Message sent successfully to user #{user_id}"
          true
        else
          Rails.logger.error "[ZALO] API Error: #{result['message']} (Code: #{result['error']})"
          false
        end
      else
        Rails.logger.error "[ZALO] HTTP Error: #{response.code} - #{response.message}"
        false
      end
    end

    # ===============================
    # Get Followers List
    # ===============================
    def get_followers(offset = 0, count = 50)
      token = get_access_token
      return [] unless token

      url = "#{ZALO_API_BASE}/#{ZALO_API_VERSION}/oa/getfollowers"

      response = HTTParty.get(
        url,
        headers: {
          'access_token' => token
        },
        query: {
          offset: offset,
          count: count
        },
        timeout: 30
      )

      log_response('get_followers', response)

      if response.success?
        result = response.parsed_response
        if result['error'] == 0
          followers = result.dig('data', 'followers') || []
          Rails.logger.info "[ZALO] Retrieved #{followers.length} followers"
          followers
        else
          Rails.logger.error "[ZALO] API Error: #{result['message']} (Code: #{result['error']})"
          []
        end
      else
        Rails.logger.error "[ZALO] HTTP Error: #{response.code} - #{response.message}"
        []
      end
    end

    # ===============================
    # Send Admin Notification
    # ===============================
    def send_admin_notification(booking)
      admin_user_id = ENV['ZALO_ADMIN_USER_IDS']
      return false unless admin_user_id

      message = build_booking_message(booking)
      send_message(admin_user_id, message)
    end

    # ===============================
    # Send Custom Message to User
    # ===============================
    def send_custom_message(user_id, message)
      send_message(user_id, message)
    end

    # ===============================
    # Build Booking Message
    # ===============================
    def build_booking_message(booking)
      <<~MESSAGE
        🔔 *ĐẶT BÀN MỚI* 🔔

        👤 *Khách hàng:* #{booking.customer_name}
        📞 *SĐT:* #{booking.customer_phone}
        📧 *Email:* #{booking.customer_email}

        👥 *Số người:* #{booking.party_size}
        📅 *Ngày:* #{booking.booking_date.strftime('%d/%m/%Y')}
        🕐 *Giờ:* #{booking.booking_time}
        ⏱️ *Thời gian:* #{booking.duration_hours} giờ

        📝 *Ghi chú:* #{booking.notes.presence || 'Không có'}

        ---
        Thời gian nhận: #{Time.current.strftime('%d/%m/%Y %H:%M')}
      MESSAGE
    end

    private

    def log_response(action, response)
      status = response.success? ? 'SUCCESS' : 'FAILED'
      Rails.logger.info "[ZALO] #{action} #{status}: #{response.code} - #{response.body[0..500]}..."
    rescue => e
      Rails.logger.error "[ZALO] Error logging response: #{e.message}"
    end
  end
end
