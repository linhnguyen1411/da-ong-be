class ChatbotFaq < ApplicationRecord
  validates :answer, presence: true
  validates :patterns, presence: true
  validates :locale, presence: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(priority: :desc, updated_at: :desc) }

  def matches?(text)
    Array(patterns).any? do |p|
      begin
        text.match?(Regexp.new(p.to_s, Regexp::IGNORECASE))
      rescue RegexpError
        false
      end
    end
  end
end


