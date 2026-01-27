module Chatbot
  class Responder
    def self.call(message:, context: {})
      new(message: message, context: context).call
    end

    def initialize(message:, context: {})
      @message = message.to_s.strip
      @context = context || {}
      @config = load_config
    end

    def call
      return fallback('Anh/chị cho em xin nội dung câu hỏi ạ.') if @message.blank?

      if room_intent?
        return respond_room_availability
      end

      faq = match_db_faq
      return faq if faq.present?

      # If no FAQ matched, delegate to AI (Gemini/OpenAI) when enabled.
      if AiProvider.enabled?
        return respond_ai
      end

      company = @context['company_name'].to_s.strip.presence
      {
        intent: 'ai_unavailable',
        reply: "Dạ em chưa hiểu rõ câu hỏi này ạ. Anh/chị có thể nói rõ hơn (vd: **ngày/giờ/số người** nếu muốn check phòng trống) để em hỗ trợ tốt hơn nhé."
      }
    end

    private

    def load_config
      path = Rails.root.join('config/chatbot.yml')
      raw = YAML.load_file(path)
      raw['vi'] || {}
    rescue StandardError
      {}
    end

    def room_intent?
      patterns = (@config.dig('room_intent', 'patterns') || [])
      patterns.any? { |p| @message.match?(/#{p}/i) }
    end

    def match_canned
      canned = @config['canned'] || []
      found = canned.find do |item|
        (item['patterns'] || []).any? { |p| @message.match?(/#{p}/i) }
      end
      return nil unless found

      {
        intent: found['id'],
        reply: found['answer'].to_s
      }
    end

    def match_db_faq
      return reminder_schema_fallback unless ActiveRecord::Base.connection_pool.with_connection { true } rescue false

      faqs = ChatbotFaq.active.where(locale: 'vi').ordered.limit(200)
      found = faqs.find { |f| f.matches?(@message) }
      return nil unless found

      {
        intent: "faq:#{found.id}",
        reply: found.answer.to_s
      }
    rescue StandardError
      nil
    end

    # When DB is not available (rare), just ignore.
    def reminder_schema_fallback
      nil
    end

    def respond_room_availability
      parsed = parse_datetime_from_message(@message)

      date = parsed[:date] || safe_parse_date(@context['date'])
      time = parsed[:time] || safe_parse_time(@context['time'])
      party_size = parsed[:party_size] || @context['party_size']

      if date.blank? || time.blank?
        return {
          intent: 'room_availability',
          reply: 'Anh/chị muốn **ngày** và **giờ** nào để em kiểm tra phòng trống ạ? (VD: 28/01 lúc 18:30)',
          required: %w[date time]
        }
      end

      # Bot "calls API" availability logic (shared endpoint uses the same service)
      rooms = Availability::RoomsForSlot.call(date: date, time: time, party_size: party_size)
      rooms_json = rooms.limit(6).map do |r|
        {
          id: r.id,
          name: r.name,
          capacity: r.capacity,
          room_type: r.room_type,
          price_per_hour: r.price_per_hour.to_s
        }
      end

      if rooms_json.empty?
        return {
          intent: 'room_availability',
          reply: "Dạ khung giờ **#{date.strftime('%d/%m/%Y')} #{time.strftime('%H:%M')}** hiện chưa thấy phòng trống. Anh/chị cho em xin giờ khác hoặc số người để em gợi ý ạ.",
          rooms: []
        }
      end

      list = rooms_json.map { |r| "- **#{r[:name]}** (#{r[:capacity]} người)" }.join("\n")
      {
        intent: 'room_availability',
        reply: "Dạ khung giờ **#{date.strftime('%d/%m/%Y')} #{time.strftime('%H:%M')}** bên em còn:\n#{list}\n\nAnh/chị muốn giữ phòng nào? Cho em xin **SĐT + số người** để em đặt giúp ạ.",
        rooms: rooms_json
      }
    end

    def respond_ai
      company = @context['company_name'].to_s.strip.presence
      provided_system = @context['system_instruction'].to_s

      # Guardrail: limit prompt size from client
      if provided_system.present? && provided_system.length <= 4000
        system = provided_system
      else
        system = <<~SYS
          Bạn là trợ lý tư vấn cho nhà hàng #{company || 'Đá & Ong'}.
          Quy tắc:
          - Trả lời ngắn gọn, lịch sự, tiếng Việt.
          - Nếu khách hỏi đặt bàn/đặt phòng: luôn hỏi lại các thông tin thiếu: SĐT, ngày, giờ, số người, phòng riêng/ngoài trời.
          - Không bịa thông tin. Nếu không chắc, hỏi lại.
        SYS
      end

      user = @message
      content = AiProvider.chat(system: system, user: user)
      content = content.presence || 'Dạ anh/chị cho em xin **ngày + giờ + số người** để em hỗ trợ nhanh nhất ạ.'

      { intent: AiProvider.provider_name, reply: content }
    rescue StandardError
      fallback('Dạ hiện em chưa xử lý được câu hỏi này. Anh/chị cho em xin **ngày + giờ + số người** để em hỗ trợ ạ.')
    end

    def fallback(text)
      { intent: 'fallback', reply: text }
    end

    # --- parsing helpers ---
    def parse_datetime_from_message(text)
      out = {}
      # party size: "2 người", "4 khách"
      if (m = text.match(/(\d{1,2})\s*(người|khách)/i))
        out[:party_size] = m[1].to_i
      end

      # date: dd/mm(/yyyy)?
      if (m = text.match(/(\d{1,2})[\/\-](\d{1,2})(?:[\/\-](\d{2,4}))?/))
        d = m[1].to_i
        mo = m[2].to_i
        y = m[3].present? ? m[3].to_i : Date.current.year
        y += 2000 if y < 100
        out[:date] = Date.new(y, mo, d) rescue nil
      end

      # time: HH:MM or "18h" or "18h30"
      if (m = text.match(/(\d{1,2})\s*(?:h|giờ)\s*(\d{1,2})?/i))
        hh = m[1].to_i
        mm = m[2].present? ? m[2].to_i : 0
        out[:time] = Time.zone.local(Date.current.year, 1, 1, hh, mm, 0) rescue nil
      elsif (m = text.match(/(\d{1,2}):(\d{2})/))
        hh = m[1].to_i
        mm = m[2].to_i
        out[:time] = Time.zone.local(Date.current.year, 1, 1, hh, mm, 0) rescue nil
      end

      out
    end

    def safe_parse_date(val)
      return nil if val.blank?
      Date.parse(val.to_s)
    rescue StandardError
      nil
    end

    def safe_parse_time(val)
      return nil if val.blank?
      Time.parse(val.to_s)
    rescue StandardError
      nil
    end
  end
end


