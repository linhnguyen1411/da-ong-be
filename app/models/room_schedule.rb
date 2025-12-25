class RoomSchedule < ApplicationRecord
  belongs_to :room
  belongs_to :booking, optional: true

  validates :schedule_date, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :status, presence: true, inclusion: { in: %w[active cancelled completed] }
  validate :end_time_after_start_time

  scope :active, -> { where(status: 'active') }
  scope :for_date, ->(date) { where(schedule_date: date) }
  scope :for_room, ->(room_id) { where(room_id: room_id) }
  scope :overlapping, ->(date, start_time, end_time) {
    where(schedule_date: date)
      .where(status: 'active')
      .where(
        '(start_time < ? AND end_time > ?) OR (start_time < ? AND end_time > ?) OR (start_time >= ? AND end_time <= ?)',
        end_time, start_time, # Overlap from left
        start_time, end_time, # Overlap from right
        start_time, end_time  # Fully contained
      )
  }

  def cancel!
    update!(status: 'cancelled')
  end

  def complete!
    update!(status: 'completed')
  end

  def active?
    status == 'active'
  end

  private

  def end_time_after_start_time
    return unless start_time && end_time

    if end_time <= start_time
      errors.add(:end_time, 'must be after start_time')
    end
  end
end

