class CreateRoomSchedules < ActiveRecord::Migration[7.1]
  def change
    create_table :room_schedules do |t|
      t.references :room, null: false, foreign_key: true
      t.references :booking, null: true, foreign_key: true # Optional - có thể tạo schedule không từ booking
      t.date :schedule_date, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.string :status, default: 'active', null: false # active, cancelled, completed
      t.text :notes

      t.timestamps
    end

    add_index :room_schedules, [:room_id, :schedule_date, :start_time], name: 'index_room_schedules_on_room_date_time'
    add_index :room_schedules, [:schedule_date, :status], name: 'index_room_schedules_on_date_status'
    add_index :room_schedules, :booking_id, name: 'index_room_schedules_on_booking_id'
  end
end
