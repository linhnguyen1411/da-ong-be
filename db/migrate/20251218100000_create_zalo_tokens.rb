class CreateZaloTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :zalo_tokens do |t|
      t.text :access_token
      t.text :refresh_token
      t.datetime :access_token_expires_at
      t.datetime :refresh_token_expires_at
      t.string :oa_id

      t.timestamps
    end

    add_index :zalo_tokens, :oa_id, unique: true
  end
end

