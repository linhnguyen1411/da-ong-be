class Customer < ApplicationRecord
  has_many :customer_visits, dependent: :destroy
  has_many :loyalty_transactions, dependent: :destroy
  has_many :bookings, dependent: :nullify

  validates :phone, presence: true, uniqueness: true

  before_validation :normalize_phone

  scope :active, -> { where(active: true) }
  scope :recent, -> { order(last_visit_at: :desc, updated_at: :desc) }

  def as_summary_json
    as_json(only: [:id, :name, :phone, :email, :active, :points_balance, :total_visits, :total_spent_vnd, :last_visit_at, :created_at, :updated_at])
  end

  private

  def normalize_phone
    return if phone.blank?
    self.phone = phone.to_s.strip.gsub(/\s+/, '')
  end
end


