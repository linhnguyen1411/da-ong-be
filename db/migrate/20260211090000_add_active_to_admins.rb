class AddActiveToAdmins < ActiveRecord::Migration[7.0]
  def change
    add_column :admins, :active, :boolean, null: false, default: true
    add_index :admins, :active
  end
end


