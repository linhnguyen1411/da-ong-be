class LoyaltyTransaction < ApplicationRecord
  belongs_to :customer
  belongs_to :booking, optional: true
  belongs_to :admin, optional: true

  KINDS = %w[earn redeem adjust].freeze

  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :points, presence: true, numericality: { only_integer: true }
  validates :occurred_at, presence: true
  validates :booking_id, uniqueness: { scope: :kind }, allow_nil: true

  before_validation :set_default_occurred_at, on: :create

  private

  def set_default_occurred_at
    self.occurred_at ||= Time.current
  end
end


