class CreateChatbotFaqs < ActiveRecord::Migration[7.1]
  def change
    create_table :chatbot_faqs do |t|
      t.string :title
      t.text :answer, null: false
      t.jsonb :patterns, null: false, default: [] # array of regex strings
      t.boolean :active, null: false, default: true
      t.integer :priority, null: false, default: 0
      t.string :locale, null: false, default: 'vi'

      t.timestamps
    end

    add_index :chatbot_faqs, :active
    add_index :chatbot_faqs, :priority
    add_index :chatbot_faqs, :locale
  end
end


