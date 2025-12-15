class AddCancelledAtToBookings < ActiveRecord::Migration[7.1]
  def change
    add_column :bookings, :cancelled_at, :datetime
  end
end
