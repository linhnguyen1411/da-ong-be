class BookingItem < ApplicationRecord
  belongs_to :booking
  belongs_to :menu_item

  validates :quantity, presence: true, numericality: { greater_than: 0 }

  before_validation :set_defaults, on: :create

  def subtotal
    menu_item.price * quantity
  end

  private

  def set_defaults
    self.quantity ||= 1
  end
end
