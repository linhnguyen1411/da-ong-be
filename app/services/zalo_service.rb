require 'httparty'

class ZaloService
  ZALO_API_BASE = 'https://openapi.zalo.me/v3.0'

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

  def self.get_followers
    access_token = get_access_token
    return [] unless access_token

    response = HTTParty.get("#{ZALO_API_BASE}/oa/getfollowers", headers: {
      'access_token' => access_token
    }, query: {
      data: { offset: 0, count: 50 }.to_json
    })

    if response.success?
      data = JSON.parse(response.body)
      followers = data['data'] || []
      Rails.logger.info "Zalo followers retrieved: #{followers.count} followers - #{followers.inspect}"
      followers
    else
      Rails.logger.error "Failed to get Zalo followers: #{response.body}"
      []
    end
  end
end
