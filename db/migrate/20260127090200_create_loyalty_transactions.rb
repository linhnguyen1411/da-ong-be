class CreateLoyaltyTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :loyalty_transactions do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :booking, null: true, foreign_key: true
      t.references :admin, null: true, foreign_key: true

      t.string :kind, null: false # earn | redeem | adjust
      t.integer :points, null: false # positive for earn/adjust, negative for redeem
      t.integer :amount_vnd # optional reference spend amount
      t.string :reference
      t.text :note
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :loyalty_transactions, :occurred_at
    add_index :loyalty_transactions, [:customer_id, :occurred_at]
    add_index :loyalty_transactions, [:booking_id, :kind], unique: true
    add_index :loyalty_transactions, :kind
  end
end


