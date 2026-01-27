class AddAmountVndToCustomerVisits < ActiveRecord::Migration[7.1]
  def change
    add_column :customer_visits, :amount_vnd, :integer
    add_index :customer_visits, :amount_vnd
  end
end


