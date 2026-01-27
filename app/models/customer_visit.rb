class CustomerVisit < ApplicationRecord
  belongs_to :customer
  belongs_to :booking, optional: true
  belongs_to :admin, optional: true

  validates :occurred_at, presence: true
  validates :source, presence: true
  validates :booking_id, uniqueness: true, allow_nil: true
  validates :amount_vnd, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  before_validation :set_default_occurred_at, on: :create

  private

  def set_default_occurred_at
    self.occurred_at ||= Time.current
  end
end


