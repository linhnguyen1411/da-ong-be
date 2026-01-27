require 'net/http'
require 'json'

class GeminiService
  def self.enabled?
    ENV['GEMINI_API_KEY'].present?
  end

  def self.model
    # Use a model name compatible with v1beta generateContent by default
    ENV['GEMINI_MODEL'].presence || 'gemini-1.5-flash-latest'
  end

  # Basic non-streaming generateContent call.
  # Docs: https://ai.google.dev/gemini-api/docs
  def self.chat(system:, user:, temperature: 0.4)
    raise 'GEMINI_API_KEY missing' unless enabled?

    uri = URI("https://generativelanguage.googleapis.com/v1beta/models/#{model}:generateContent")
    uri.query = "key=#{ENV['GEMINI_API_KEY']}"

    payload = {
      system_instruction: { parts: [{ text: system.to_s }] },
      contents: [
        { role: 'user', parts: [{ text: user.to_s }] }
      ],
      generationConfig: { temperature: temperature }
    }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = 'application/json'
    req.body = JSON.dump(payload)

    res = http.request(req)
    raise "Gemini HTTP #{res.code}: #{res.body.to_s[0, 300]}" unless res.is_a?(Net::HTTPSuccess)

    json = JSON.parse(res.body)
    json.dig('candidates', 0, 'content', 'parts', 0, 'text').to_s
  rescue JSON::ParserError
    ''
  end
end


