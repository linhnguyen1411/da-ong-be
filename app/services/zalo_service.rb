# app/services/zalo_service.rb
require 'httparty'

class ZaloService
  ZALO_API_V3 = 'https://openapi.zalo.me/v3.0'

  class << self
    def access_token
      ENV['ZALO_OA_ACCESS_TOKEN']
    end

    # ===============================
    # Send message (v3.0)
    # ===============================
    def send_message(user_id, text)
      response = HTTParty.post(
        "#{ZALO_API_V3}/oa/message/cs",
        headers: {
          'access_token' => access_token,
          'Content-Type' => 'application/json'
        },
        body: {
          recipient: { user_id: user_id },
          message: { text: text }
        }.to_json
      )
      log_response('send_message', response)
      response.success?
    end

    # ===============================
    # Send admin notification
    # ===============================
    def send_admin_notification(booking)
      admin_user_id = ENV['ZALO_ADMIN_USER_IDS']
      return unless admin_user_id

      message = "Có đặt bàn mới!\n" +
                "Tên khách hàng: #{booking.customer_name}\n" +
                "Số điện thoại: #{booking.customer_phone}\n" +
                "Số lượng khách: #{booking.party_size}\n" +
                "Ngày: #{booking.booking_date}\n" +
                "Giờ: #{booking.booking_time}\n" +
                "Thời gian: #{booking.duration_hours} giờ\n" +
                "Ghi chú: #{booking.notes}"

      send_message(admin_user_id, message)
    end

    private

    def log_response(action, response)
      if response.success?
        Rails.logger.info "[ZALO] #{action} success: #{response.body}"
      else
        Rails.logger.error "[ZALO] #{action} failed: #{response.body}"
      end
    end
  end
end
