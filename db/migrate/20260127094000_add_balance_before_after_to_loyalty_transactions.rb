class AddBalanceBeforeAfterToLoyaltyTransactions < ActiveRecord::Migration[7.1]
  def change
    add_column :loyalty_transactions, :balance_before, :integer
    add_column :loyalty_transactions, :balance_after, :integer

    add_index :loyalty_transactions, :balance_after
  end
end


