class AddProductCodeAndUnitToMenuItems < ActiveRecord::Migration[7.1]
  def change
    add_column :menu_items, :product_code, :string
    add_column :menu_items, :unit, :string
    add_index :menu_items, :product_code
  end
end
