class Booking < ApplicationRecord
  belongs_to :room, optional: true
  has_many :booking_items, dependent: :destroy
  has_many :menu_items, through: :booking_items

  validates :customer_name, presence: true
  validates :customer_phone, presence: true
  validates :party_size, presence: true, numericality: { greater_than: 0 }
  validates :booking_date, presence: true
  validates :booking_time, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending confirmed cancelled completed] }

  before_validation :set_defaults, on: :create

  scope :pending, -> { where(status: 'pending') }
  scope :confirmed, -> { where(status: 'confirmed') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :completed, -> { where(status: 'completed') }
  scope :today, -> { where(booking_date: Date.current) }
  scope :upcoming, -> { where('booking_date >= ?', Date.current).order(booking_date: :asc, booking_time: :asc) }
  scope :recent, -> { order(created_at: :desc) }

  accepts_nested_attributes_for :booking_items, allow_destroy: true

  def confirm!
    update!(status: 'confirmed', confirmed_at: Time.current)
    # Đánh dấu phòng đang sử dụng nếu booking hôm nay
    room&.update!(status: 'occupied') if booking_date == Date.current
  end

  def cancel!
    update!(status: 'cancelled', cancelled_at: Time.current)
    # Trả phòng về trạng thái trống nếu không còn booking nào khác
    release_room_if_no_other_bookings
  end

  def complete!
    update!(status: 'completed')
    # Trả phòng về trạng thái trống
    release_room_if_no_other_bookings
  end

  def total_amount
    booking_items.includes(:menu_item).sum { |item| item.menu_item.price * item.quantity }
  end

  private

  def release_room_if_no_other_bookings
    return unless room
    
    # Kiểm tra xem còn booking nào khác cho phòng này hôm nay không
    other_bookings = room.bookings
                         .where(booking_date: Date.current)
                         .where(status: ['pending', 'confirmed'])
                         .where.not(id: id)
    
    room.update!(status: 'available') if other_bookings.empty?
  end

  def set_defaults
    self.status ||= 'pending'
    self.duration_hours ||= 2
  end
end
