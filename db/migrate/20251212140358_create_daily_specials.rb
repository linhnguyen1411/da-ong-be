class CreateDailySpecials < ActiveRecord::Migration[7.1]
  def change
    create_table :daily_specials do |t|
      t.references :menu_item, null: false, foreign_key: true
      t.string :title
      t.text :content
      t.string :image_url
      t.date :special_date
      t.boolean :pinned
      t.boolean :highlighted
      t.boolean :active

      t.timestamps
    end
  end
end
