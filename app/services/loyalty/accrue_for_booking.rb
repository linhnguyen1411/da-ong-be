module Loyalty
  class AccrueForBooking
    def self.call(booking, admin: nil)
      new(booking, admin: admin).call
    end

    def initialize(booking, admin: nil)
      @booking = booking
      @admin = admin
    end

    def call
      return unless @booking.present?
      return unless @booking.status == 'completed'

      phone = @booking.customer_phone.to_s.strip.gsub(/\s+/, '')
      return if phone.blank?

      ActiveRecord::Base.transaction do
        customer = Customer.find_or_initialize_by(phone: phone)
        customer.name = @booking.customer_name if customer.name.blank? && @booking.customer_name.present?
        customer.email = @booking.customer_email if customer.email.blank? && @booking.customer_email.present?
        customer.save! if customer.changed? || customer.new_record?

        # Link booking -> customer for reporting
        if @booking.respond_to?(:customer_id) && @booking.customer_id.blank?
          @booking.update!(customer_id: customer.id)
        end

        occurred_at = infer_occurred_at(@booking)

        # 1 booking completed -> 1 visit (idempotent via unique booking_id)
        visit = CustomerVisit.find_or_create_by!(booking_id: @booking.id) do |v|
          v.customer_id = customer.id
          v.admin_id = @admin&.id
          v.source = 'booking_completed'
          v.occurred_at = occurred_at
          v.note = 'Auto from booking completion'
        end

        # If visit was newly created, update aggregates
        if visit.previously_new_record?
          customer.total_visits += 1
          customer.last_visit_at = [customer.last_visit_at, occurred_at].compact.max
        end

        amount_vnd = safe_amount_vnd(@booking)
        if visit.previously_new_record? && visit.amount_vnd.nil? && amount_vnd.positive?
          visit.update!(amount_vnd: amount_vnd)
        end
        customer.total_spent_vnd += amount_vnd if amount_vnd.positive?

        points = calculate_points(amount_vnd) + Loyalty::Config.visit_bonus_points
        if points.positive?
          before_points = customer.points_balance.to_i
          after_points = before_points + points

          tx = LoyaltyTransaction.find_or_create_by!(booking_id: @booking.id, kind: 'earn') do |t|
            t.customer_id = customer.id
            t.admin_id = @admin&.id
            t.points = points
            t.amount_vnd = amount_vnd
            t.balance_before = before_points
            t.balance_after = after_points
            t.reference = "booking:#{@booking.id}"
            t.note = 'Auto earn from booking completion'
            t.occurred_at = occurred_at
          end

          if tx.previously_new_record?
            customer.points_balance += points
          end
        end

        customer.save! if customer.changed?
      end
    end

    private

    def safe_amount_vnd(booking)
      raw = booking.total_amount
      return 0 if raw.nil?
      # total_amount may be BigDecimal
      raw.to_d.to_i
    rescue StandardError
      0
    end

    def calculate_points(amount_vnd)
      vnd_per_point = Loyalty::Config.vnd_per_point
      return 0 if vnd_per_point <= 0

      points_per_point = Loyalty::Config.points_per_point
      return 0 if points_per_point <= 0

      (amount_vnd / vnd_per_point) * points_per_point
    end

    def infer_occurred_at(booking)
      date = booking.booking_date
      time = booking.booking_time

      if date.present? && time.present?
        Time.zone.local(date.year, date.month, date.day, time.hour, time.min, time.sec)
      else
        booking.updated_at || Time.current
      end
    rescue StandardError
      booking.updated_at || Time.current
    end
  end
end


