class CreateBookings < ActiveRecord::Migration[7.1]
  def change
    create_table :bookings do |t|
      t.references :room, null: false, foreign_key: true
      t.string :customer_name
      t.string :customer_phone
      t.string :customer_email
      t.integer :party_size
      t.date :booking_date
      t.time :booking_time
      t.integer :duration_hours
      t.text :notes
      t.string :status
      t.datetime :confirmed_at

      t.timestamps
    end
  end
end
