class CreateBestSellers < ActiveRecord::Migration[7.1]
  def change
    create_table :best_sellers do |t|
      t.references :menu_item, null: false, foreign_key: true
      t.string :title
      t.text :content
      t.string :image_url
      t.boolean :pinned
      t.boolean :highlighted
      t.integer :position
      t.boolean :active

      t.timestamps
    end
  end
end
