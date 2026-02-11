class CreateBookingActionLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :booking_action_logs do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :admin, null: false, foreign_key: true
      t.string :action, null: false
      t.jsonb :changeset, null: false, default: {}
      t.timestamps
    end

    add_index :booking_action_logs, [:booking_id, :created_at]
  end
end


