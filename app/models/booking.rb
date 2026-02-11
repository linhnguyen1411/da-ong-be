class Booking < ApplicationRecord
  belongs_to :room, optional: true
  belongs_to :customer, optional: true
  has_many :booking_items, dependent: :destroy
  has_many :menu_items, through: :booking_items
  has_one :room_schedule, dependent: :destroy
  has_many :booking_action_logs, dependent: :destroy

  validates :customer_phone, presence: true
  validates :party_size, presence: true, numericality: { greater_than: 0 }
  validates :booking_date, presence: true
  validates :booking_time, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending confirmed cancelled completed] }

  before_validation :set_defaults, on: :create
  before_validation :ensure_customer_from_phone, if: -> { customer_phone.present? && (new_record? || will_save_change_to_customer_phone?) }

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
    # Tạo room_schedule khi confirm booking có phòng
    create_room_schedule! if room.present?
  end

  def cancel!
    update!(status: 'cancelled', cancelled_at: Time.current)
    # Hủy room_schedule nếu có
    room_schedule&.cancel!
  end

  def complete!
    update!(status: 'completed')
    # Đánh dấu room_schedule là completed
    room_schedule&.complete!
  end

  def total_amount
    booking_items.includes(:menu_item).sum { |item| item.menu_item.price * item.quantity }
  end

  # Helper to format booking_time in the application's timezone
  def formatted_booking_time
    booking_time&.strftime('%H:%M')
  end

  private

  def create_room_schedule!
    return if room_schedule.present? # Đã có schedule rồi
    return unless room.present? # Không có phòng thì không tạo schedule

    # Tính end_time từ start_time + duration_hours
    # booking_time là Time object, extract chỉ time part (HH:MM:SS)
    start_time_str = booking_time.strftime('%H:%M:%S')
    # Tính end_time: lấy time part từ booking_time + duration
    end_time_obj = booking_time + (duration_hours || 2).hours
    end_time_str = end_time_obj.strftime('%H:%M:%S')

    RoomSchedule.create!(
      room: room,
      booking: self,
      schedule_date: booking_date,
      start_time: start_time_str, # Lưu dạng string "HH:MM:SS"
      end_time: end_time_str,      # Lưu dạng string "HH:MM:SS"
      status: 'active'
    )
  end

  def set_defaults
    self.status ||= 'pending'
    self.duration_hours ||= 2
  end

  # Auto-sync booking customer info with loyalty "Customer" record.
  # - Uses customer_phone to find/create Customer.
  # - Links booking.customer_id for reporting and future loyalty actions.
  def ensure_customer_from_phone
    normalized_phone = customer_phone.to_s.strip.gsub(/\s+/, '')
    return if normalized_phone.blank?

    # Normalize stored booking phone for consistent matching
    self.customer_phone = normalized_phone

    customer = Customer.find_or_initialize_by(phone: normalized_phone)
    customer.name = customer_name if customer.name.blank? && customer_name.present?
    customer.email = customer_email if customer.email.blank? && customer_email.present?
    customer.save! if customer.new_record? || customer.changed?

    self.customer = customer
  end
end
