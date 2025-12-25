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

ActiveRecord::Schema[7.1].define(version: 2025_12_25_081202) do
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
    t.string "unit"
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
  add_foreign_key "bookings", "rooms"
  add_foreign_key "daily_specials", "menu_items"
  add_foreign_key "menu_items", "categories"
  add_foreign_key "room_images", "rooms"
  add_foreign_key "room_schedules", "bookings"
  add_foreign_key "room_schedules", "rooms"
end
