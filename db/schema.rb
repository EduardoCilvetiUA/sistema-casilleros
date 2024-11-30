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

ActiveRecord::Schema[7.2].define(version: 2024_11_29_033720) do
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

  create_table "controllers", force: :cascade do |t|
    t.string "name"
    t.string "location"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_connected", default: false
    t.datetime "last_connection"
    t.bigint "model_id", null: false
    t.index ["model_id"], name: "index_controllers_on_model_id"
    t.index ["user_id"], name: "index_controllers_on_user_id"
  end

  create_table "gestures", force: :cascade do |t|
    t.string "name"
    t.string "symbol"
    t.bigint "model_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["model_id"], name: "index_gestures_on_model_id"
  end

  create_table "locker_events", force: :cascade do |t|
    t.bigint "locker_id", null: false
    t.string "event_type"
    t.boolean "success"
    t.datetime "event_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["locker_id"], name: "index_locker_events_on_locker_id"
  end

  create_table "locker_passwords", force: :cascade do |t|
    t.bigint "locker_id", null: false
    t.bigint "gesture_id", null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gesture_id"], name: "index_locker_passwords_on_gesture_id"
    t.index ["locker_id"], name: "index_locker_passwords_on_locker_id"
  end

  create_table "lockers", force: :cascade do |t|
    t.integer "number"
    t.boolean "state"
    t.string "owner_email"
    t.bigint "controller_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["controller_id"], name: "index_lockers_on_controller_id"
  end

  create_table "model_updates", force: :cascade do |t|
    t.bigint "controller_id", null: false
    t.bigint "model_id", null: false
    t.string "status"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "previous_model_id"
    t.index ["controller_id"], name: "index_model_updates_on_controller_id"
    t.index ["model_id"], name: "index_model_updates_on_model_id"
    t.index ["previous_model_id"], name: "index_model_updates_on_previous_model_id"
  end

  create_table "models", force: :cascade do |t|
    t.string "name"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "size_bytes"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.string "avatar_url"
    t.string "uid"
    t.string "provider"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_superuser", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "controllers", "models"
  add_foreign_key "controllers", "users"
  add_foreign_key "gestures", "models"
  add_foreign_key "locker_events", "lockers"
  add_foreign_key "locker_passwords", "gestures"
  add_foreign_key "locker_passwords", "lockers"
  add_foreign_key "lockers", "controllers"
  add_foreign_key "model_updates", "controllers"
  add_foreign_key "model_updates", "models"
  add_foreign_key "model_updates", "models", column: "previous_model_id"
end
