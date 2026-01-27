require 'net/http'
require 'json'

class OpenAiService
  OPENAI_URL = URI('https://api.openai.com/v1/chat/completions')

  def self.enabled?
    ENV['OPENAI_API_KEY'].present?
  end

  def self.chat(system:, user:, model: nil, temperature: 0.4)
    raise 'OPENAI_API_KEY missing' unless enabled?

    model ||= ENV['OPENAI_MODEL'].presence || 'gpt-4o-mini'

    payload = {
      model: model,
      temperature: temperature,
      messages: [
        { role: 'system', content: system.to_s },
        { role: 'user', content: user.to_s }
      ]
    }

    http = Net::HTTP.new(OPENAI_URL.host, OPENAI_URL.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(OPENAI_URL)
    req['Authorization'] = "Bearer #{ENV['OPENAI_API_KEY']}"
    req['Content-Type'] = 'application/json'
    req.body = JSON.dump(payload)

    res = http.request(req)
    raise "OpenAI HTTP #{res.code}: #{res.body.to_s[0, 300]}" unless res.is_a?(Net::HTTPSuccess)

    json = JSON.parse(res.body)
    json.dig('choices', 0, 'message', 'content').to_s
  rescue JSON::ParserError
    ''
  end
end


