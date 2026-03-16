# frozen_string_literal: true

namespace :recruitments do
  desc "Create recruitments table if not exists (fix for 500 error)"
  task ensure_table: :environment do
    conn = ActiveRecord::Base.connection
    unless conn.table_exists?(:recruitments)
      puts "Creating recruitments table..."
      conn.create_table :recruitments do |t|
        t.string :title, null: false
        t.text :content
        t.string :department
        t.integer :position, null: false, default: 0
        t.boolean :active, null: false, default: true
        t.timestamps
      end
      conn.add_index :recruitments, :active
      conn.add_index :recruitments, :position
      puts "✅ Recruitments table created."
    else
      puts "✅ Recruitments table already exists."
    end
  end
end
