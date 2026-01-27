class CreateCustomers < ActiveRecord::Migration[7.1]
  def change
    create_table :customers do |t|
      t.string  :name
      t.string  :phone, null: false
      t.string  :email
      t.text    :notes

      t.boolean :active, default: true, null: false

      # Loyalty aggregates (denormalized for fast admin dashboard)
      t.integer :points_balance, default: 0, null: false
      t.integer :total_visits, default: 0, null: false
      t.integer :total_spent_vnd, default: 0, null: false
      t.datetime :last_visit_at

      t.timestamps
    end

    add_index :customers, :phone, unique: true
    add_index :customers, :active
    add_index :customers, :last_visit_at
  end
end


