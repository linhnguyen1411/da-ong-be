# frozen_string_literal: true

class CreatePromotions < ActiveRecord::Migration[7.1]
  def change
    create_table :promotions do |t|
      t.string :title, null: false
      t.text :content
      t.string :image_url
      t.boolean :highlighted, default: false, null: false
      t.integer :position, default: 0, null: false
      t.boolean :active, default: true, null: false
      t.datetime :start_at
      t.datetime :end_at

      t.timestamps
    end

    add_index :promotions, :active
    add_index :promotions, :highlighted
    add_index :promotions, :position
  end
end
