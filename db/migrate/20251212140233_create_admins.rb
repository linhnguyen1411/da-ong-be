class CreateAdmins < ActiveRecord::Migration[7.1]
  def change
    create_table :admins do |t|
      t.string :email
      t.string :password_digest
      t.string :name
      t.string :role

      t.timestamps
    end
  end
end
