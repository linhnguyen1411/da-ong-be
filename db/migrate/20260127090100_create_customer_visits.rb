class CreateCustomerVisits < ActiveRecord::Migration[7.1]
  def change
    create_table :customer_visits do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :booking, null: true, foreign_key: true, index: { unique: true }
      t.references :admin, null: true, foreign_key: true

      t.string :source, null: false, default: 'manual' # manual | booking_completed
      t.datetime :occurred_at, null: false
      t.text :note

      t.timestamps
    end

    add_index :customer_visits, :occurred_at
    add_index :customer_visits, [:customer_id, :occurred_at]
  end
end


