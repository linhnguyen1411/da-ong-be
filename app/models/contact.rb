class Contact < ApplicationRecord
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true

  before_validation :set_defaults, on: :create

  scope :unread, -> { where(read: false) }
  scope :read_contacts, -> { where(read: true) }
  scope :recent, -> { order(created_at: :desc) }

  def mark_as_read!
    update!(read: true, read_at: Time.current)
  end

  def mark_as_unread!
    update!(read: false, read_at: nil)
  end

  private

  def set_defaults
    self.read = false if read.nil?
  end
end
