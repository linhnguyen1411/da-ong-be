class CreateMenuImages < ActiveRecord::Migration[7.1]
  def change
    create_table :menu_images do |t|
      t.integer :position, default: 0
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
