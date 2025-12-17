require 'httparty'

class ZaloService
  ZALO_API_BASE = 'https://openapi.zalo.me/v2.0'

  def self.get_access_token
    app_id = ENV['ZALO_APP_ID']
    app_secret = ENV['ZALO_APP_SECRET']

    return nil unless app_id && app_secret

    response = HTTParty.post("#{ZALO_API_BASE}/oa/access_token", body: {
      app_id: app_id,
      app_secret: app_secret
    })

    if response.success?
      JSON.parse(response.body)['access_token']
    else
      Rails.logger.error "Failed to get Zalo access token: #{response.body}"
      nil
    end
  end

  def self.send_message(recipient_id, message)
    access_token = get_access_token
    return unless access_token

    response = HTTParty.post("#{ZALO_API_BASE}/oa/message", headers: {
      'access_token' => access_token,
      'Content-Type' => 'application/json'
    }, body: {
      recipient: { user_id: recipient_id },
      message: { text: message }
    }.to_json)

    if response.success?
      Rails.logger.info "Zalo message sent successfully to #{recipient_id}"
    else
      Rails.logger.error "Failed to send Zalo message: #{response.body}"
    end
  end

  def self.send_admin_notification(booking)
    admin_user_id = ENV['ZALO_ADMIN_USER_ID']
    Rails.logger.info "ZaloService: admin_user_id = #{admin_user_id}"
    return unless admin_user_id

    message = "Đặt bàn mới: #{booking.customer_name} - #{booking.customer_phone} - #{booking.booking_date} #{booking.booking_time} - Số khách: #{booking.party_size}"
    Rails.logger.info "ZaloService: sending message '#{message}' to #{admin_user_id}"

    send_message(admin_user_id, message)
  end
end
