class BookingActionLog < ApplicationRecord
  belongs_to :booking
  belongs_to :admin

  validates :action, presence: true
end


