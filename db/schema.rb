# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_01_27_095500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admins", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.string "name"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "best_sellers", force: :cascade do |t|
    t.bigint "menu_item_id", null: false
    t.string "title"
    t.text "content"
    t.string "image_url"
    t.boolean "pinned"
    t.boolean "highlighted"
    t.integer "position"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_item_id"], name: "index_best_sellers_on_menu_item_id"
  end

  create_table "booking_items", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.bigint "menu_item_id", null: false
    t.integer "quantity"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_booking_items_on_booking_id"
    t.index ["menu_item_id"], name: "index_booking_items_on_menu_item_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.bigint "room_id", null: false
    t.string "customer_name"
    t.string "customer_phone"
    t.string "customer_email"
    t.integer "party_size"
    t.date "booking_date"
    t.time "booking_time"
    t.integer "duration_hours"
    t.text "notes"
    t.string "status"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "cancelled_at"
    t.bigint "customer_id"
    t.index ["customer_id"], name: "index_bookings_on_customer_id"
    t.index ["room_id"], name: "index_bookings_on_room_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "position"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "chatbot_faqs", force: :cascade do |t|
    t.string "title"
    t.text "answer", null: false
    t.jsonb "patterns", default: [], null: false
    t.boolean "active", default: true, null: false
    t.integer "priority", default: 0, null: false
    t.string "locale", default: "vi", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_chatbot_faqs_on_active"
    t.index ["locale"], name: "index_chatbot_faqs_on_locale"
    t.index ["priority"], name: "index_chatbot_faqs_on_priority"
  end

  create_table "contacts", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.string "subject"
    t.text "message"
    t.boolean "read"
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "customer_visits", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "booking_id"
    t.bigint "admin_id"
    t.string "source", default: "manual", null: false
    t.datetime "occurred_at", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "amount_vnd"
    t.index ["admin_id"], name: "index_customer_visits_on_admin_id"
    t.index ["amount_vnd"], name: "index_customer_visits_on_amount_vnd"
    t.index ["booking_id"], name: "index_customer_visits_on_booking_id", unique: true
    t.index ["customer_id", "occurred_at"], name: "index_customer_visits_on_customer_id_and_occurred_at"
    t.index ["customer_id"], name: "index_customer_visits_on_customer_id"
    t.index ["occurred_at"], name: "index_customer_visits_on_occurred_at"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.string "phone", null: false
    t.string "email"
    t.text "notes"
    t.boolean "active", default: true, null: false
    t.integer "points_balance", default: 0, null: false
    t.integer "total_visits", default: 0, null: false
    t.integer "total_spent_vnd", default: 0, null: false
    t.datetime "last_visit_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_customers_on_active"
    t.index ["last_visit_at"], name: "index_customers_on_last_visit_at"
    t.index ["phone"], name: "index_customers_on_phone", unique: true
  end

  create_table "daily_specials", force: :cascade do |t|
    t.bigint "menu_item_id", null: false
    t.string "title"
    t.text "content"
    t.string "image_url"
    t.date "special_date"
    t.boolean "pinned"
    t.boolean "highlighted"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_item_id"], name: "index_daily_specials_on_menu_item_id"
  end

  create_table "loyalty_transactions", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "booking_id"
    t.bigint "admin_id"
    t.string "kind", null: false
    t.integer "points", null: false
    t.integer "amount_vnd"
    t.string "reference"
    t.text "note"
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "balance_before"
    t.integer "balance_after"
    t.index ["admin_id"], name: "index_loyalty_transactions_on_admin_id"
    t.index ["balance_after"], name: "index_loyalty_transactions_on_balance_after"
    t.index ["booking_id", "kind"], name: "index_loyalty_transactions_on_booking_id_and_kind", unique: true
    t.index ["booking_id"], name: "index_loyalty_transactions_on_booking_id"
    t.index ["customer_id", "occurred_at"], name: "index_loyalty_transactions_on_customer_id_and_occurred_at"
    t.index ["customer_id"], name: "index_loyalty_transactions_on_customer_id"
    t.index ["kind"], name: "index_loyalty_transactions_on_kind"
    t.index ["occurred_at"], name: "index_loyalty_transactions_on_occurred_at"
  end

  create_table "menu_images", force: :cascade do |t|
    t.integer "position", default: 0
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "menu_items", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.string "name"
    t.text "description"
    t.decimal "price"
    t.string "image_url"
    t.boolean "active"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_market_price", default: false, null: false
    t.string "product_code"
    t.integer "unit", default: 0, null: false
    t.index ["category_id"], name: "index_menu_items_on_category_id"
    t.index ["product_code"], name: "index_menu_items_on_product_code"
  end

  create_table "room_images", force: :cascade do |t|
    t.bigint "room_id", null: false
    t.string "image_url"
    t.string "caption"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id"], name: "index_room_images_on_room_id"
  end

  create_table "room_schedules", force: :cascade do |t|
    t.bigint "room_id", null: false
    t.bigint "booking_id"
    t.date "schedule_date", null: false
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.string "status", default: "active", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_room_schedules_on_booking_id"
    t.index ["room_id", "schedule_date", "start_time"], name: "index_room_schedules_on_room_date_time"
    t.index ["room_id"], name: "index_room_schedules_on_room_id"
    t.index ["schedule_date", "status"], name: "index_room_schedules_on_date_status"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "capacity"
    t.boolean "has_sound_system"
    t.boolean "has_projector"
    t.boolean "has_karaoke"
    t.decimal "price_per_hour"
    t.string "status"
    t.integer "position"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "room_type", default: "private"
  end

  create_table "zalo_tokens", force: :cascade do |t|
    t.text "access_token"
    t.text "refresh_token"
    t.datetime "access_token_expires_at"
    t.datetime "refresh_token_expires_at"
    t.string "oa_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["oa_id"], name: "index_zalo_tokens_on_oa_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "best_sellers", "menu_items"
  add_foreign_key "booking_items", "bookings"
  add_foreign_key "booking_items", "menu_items"
  add_foreign_key "bookings", "customers"
  add_foreign_key "bookings", "rooms"
  add_foreign_key "customer_visits", "admins"
  add_foreign_key "customer_visits", "bookings"
  add_foreign_key "customer_visits", "customers"
  add_foreign_key "daily_specials", "menu_items"
  add_foreign_key "loyalty_transactions", "admins"
  add_foreign_key "loyalty_transactions", "bookings"
  add_foreign_key "loyalty_transactions", "customers"
  add_foreign_key "menu_items", "categories"
  add_foreign_key "room_images", "rooms"
  add_foreign_key "room_schedules", "bookings"
  add_foreign_key "room_schedules", "rooms"
end
