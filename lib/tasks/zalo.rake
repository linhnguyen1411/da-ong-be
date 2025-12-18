# lib/tasks/zalo.rake
namespace :zalo do
  desc "Initialize Zalo OA tokens (get from API Explorer: https://developers.zalo.me/tools/explorer/)"
  task :init_tokens, [:access_token, :refresh_token] => :environment do |t, args|
    if args[:access_token].blank? || args[:refresh_token].blank?
      puts "Usage: rails zalo:init_tokens[ACCESS_TOKEN,REFRESH_TOKEN]"
      puts ""
      puts "To get tokens:"
      puts "1. Go to https://developers.zalo.me/tools/explorer/"
      puts "2. Select your app and 'OA Access Token'"
      puts "3. Click 'Lấy Access Token' and select your OA"
      puts "4. Copy Access Token and Refresh Token"
      exit 1
    end

    token = ZaloService.initialize_tokens(
      access_token: args[:access_token],
      refresh_token: args[:refresh_token]
    )

    puts "✅ Tokens initialized successfully!"
    puts "   Access Token expires at: #{token.access_token_expires_at}"
    puts "   Refresh Token expires at: #{token.refresh_token_expires_at}"
  end

  desc "Check Zalo token status"
  task status: :environment do
    token = ZaloToken.first

    if token.nil?
      puts "❌ No tokens found. Run 'rails zalo:init_tokens[ACCESS_TOKEN,REFRESH_TOKEN]' first."
      exit 1
    end

    puts "📊 Zalo Token Status:"
    puts "   Access Token: #{token.access_token[0..20]}..."
    puts "   Access Token Expires: #{token.access_token_expires_at}"
    puts "   Access Token Expired: #{token.access_token_expired? ? '❌ YES' : '✅ NO'}"
    puts ""
    puts "   Refresh Token: #{token.refresh_token[0..20]}..."
    puts "   Refresh Token Expires: #{token.refresh_token_expires_at}"
    puts "   Refresh Token Expired: #{token.refresh_token_expired? ? '❌ YES' : '✅ NO'}"
  end

  desc "Manually refresh access token"
  task refresh: :environment do
    result = ZaloService.refresh_access_token
    
    if result
      puts "✅ Token refreshed successfully!"
      token = ZaloToken.first
      puts "   New Access Token expires at: #{token.access_token_expires_at}"
    else
      puts "❌ Failed to refresh token. Check logs for details."
    end
  end

  desc "Test send message to admin"
  task test_message: :environment do
    admin_id = ENV['ZALO_ADMIN_USER_IDS']
    
    if admin_id.blank?
      puts "❌ ZALO_ADMIN_USER_IDS not set in environment"
      exit 1
    end

    result = ZaloService.send_message(admin_id, "🧪 Test message from Đá & Ông restaurant system at #{Time.current}")
    
    if result
      puts "✅ Test message sent successfully!"
    else
      puts "❌ Failed to send message. Check logs for details."
    end
  end
end

