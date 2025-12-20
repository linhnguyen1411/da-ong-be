class AddIsMarketPriceToMenuItems < ActiveRecord::Migration[7.1]
  def change
    add_column :menu_items, :is_market_price, :boolean, default: false, null: false
  end
end
