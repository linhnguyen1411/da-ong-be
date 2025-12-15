class CreateBookingItems < ActiveRecord::Migration[7.1]
  def change
    create_table :booking_items do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :menu_item, null: false, foreign_key: true
      t.integer :quantity
      t.text :notes

      t.timestamps
    end
  end
end
