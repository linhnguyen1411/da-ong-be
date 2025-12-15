class CreateRoomImages < ActiveRecord::Migration[7.1]
  def change
    create_table :room_images do |t|
      t.references :room, null: false, foreign_key: true
      t.string :image_url
      t.string :caption
      t.integer :position

      t.timestamps
    end
  end
end
