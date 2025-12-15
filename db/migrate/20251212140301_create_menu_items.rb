class CreateMenuItems < ActiveRecord::Migration[7.1]
  def change
    create_table :menu_items do |t|
      t.references :category, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.decimal :price
      t.string :image_url
      t.boolean :active
      t.integer :position

      t.timestamps
    end
  end
end
