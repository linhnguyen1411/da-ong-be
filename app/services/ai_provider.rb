class AiProvider
  def self.enabled?
    GeminiService.enabled? || OpenAiService.enabled?
  end

  def self.provider_name
    return 'gemini' if GeminiService.enabled?
    return 'openai' if OpenAiService.enabled?
    'none'
  end

  def self.chat(system:, user:, temperature: 0.4)
    if GeminiService.enabled?
      return GeminiService.chat(system: system, user: user, temperature: temperature)
    end
    if OpenAiService.enabled?
      return OpenAiService.chat(system: system, user: user, temperature: temperature)
    end
    ''
  end
end


