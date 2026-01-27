module Availability
  class RoomsForSlot
    DEFAULT_WINDOW_HOURS = 2

    def self.call(date:, time:, party_size: nil, window_hours: DEFAULT_WINDOW_HOURS)
      new(date: date, time: time, party_size: party_size, window_hours: window_hours).call
    end

    def initialize(date:, time:, party_size: nil, window_hours: DEFAULT_WINDOW_HOURS)
      @date = date
      @time = time
      @party_size = party_size
      @window_hours = window_hours
    end

    def call
      rooms = Room.active.available.ordered
      rooms = rooms.where("capacity >= ?", @party_size.to_i) if @party_size.present?

      from_time = (@time - @window_hours.hours)
      to_time = (@time + @window_hours.hours)

      # Booking records are the source of truth for "reserved" (pending/confirmed)
      reserved_room_ids = Booking
        .where(booking_date: @date)
        .where(status: %w[pending confirmed])
        .where("booking_time BETWEEN ? AND ?", from_time, to_time)
        .where.not(room_id: nil)
        .distinct
        .pluck(:room_id)

      rooms.where.not(id: reserved_room_ids)
    end
  end
end


