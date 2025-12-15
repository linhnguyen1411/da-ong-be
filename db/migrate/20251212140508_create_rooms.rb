class CreateRooms < ActiveRecord::Migration[7.1]
  def change
    create_table :rooms do |t|
      t.string :name
      t.text :description
      t.integer :capacity
      t.boolean :has_sound_system
      t.boolean :has_projector
      t.boolean :has_karaoke
      t.decimal :price_per_hour
      t.string :status
      t.integer :position
      t.boolean :active

      t.timestamps
    end
  end
end
