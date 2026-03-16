# frozen_string_literal: true

class CreateRecruitments < ActiveRecord::Migration[7.1]
  def change
    create_table :recruitments do |t|
      t.string :title, null: false
      t.text :content
      t.string :department
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :recruitments, :active
    add_index :recruitments, :position
  end
end
