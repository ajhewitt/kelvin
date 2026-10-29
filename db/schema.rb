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

ActiveRecord::Schema[8.1].define(version: 2026_10_29_200228) do
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

  create_table "actuators", force: :cascade do |t|
    t.string "type", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_actuators_on_slug", unique: true
    t.index ["type"], name: "index_actuators_on_type"
  end

  create_table "brands", force: :cascade do |t|
    t.string "name", null: false
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_brands_on_name", unique: true
  end

  create_table "configurations", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_configurations_on_slug", unique: true
  end

  create_table "control_actions", force: :cascade do |t|
    t.integer "session_id", null: false
    t.integer "actuator_id", null: false
    t.string "action_value", null: false
    t.datetime "executed_at", null: false
    t.index ["actuator_id"], name: "index_control_actions_on_actuator_id"
    t.index ["session_id"], name: "index_control_actions_on_session_id"
  end

  create_table "drink_packages", force: :cascade do |t|
    t.integer "event_id", null: false
    t.integer "drink_id", null: false
    t.integer "package_id", null: false
    t.integer "position", null: false
    t.string "emoji"
    t.boolean "show_image", default: true, null: false
    t.boolean "kicked", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["drink_id"], name: "index_drink_packages_on_drink_id"
    t.index ["event_id", "drink_id", "package_id"], name: "index_drink_packages_on_event_id_and_drink_id_and_package_id", unique: true
    t.index ["package_id"], name: "index_drink_packages_on_package_id"
  end

  create_table "drinks", force: :cascade do |t|
    t.integer "brand_id"
    t.string "name", null: false
    t.text "description"
    t.decimal "abv", precision: 5, scale: 2
    t.integer "ibu"
    t.decimal "srm", precision: 4, scale: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["brand_id"], name: "index_drinks_on_brand_id"
  end

  create_table "events", force: :cascade do |t|
    t.date "date", null: false
    t.string "name", null: false
    t.string "tagline"
    t.text "description"
    t.boolean "show_abv", default: true, null: false
    t.boolean "show_ibu", default: false, null: false
    t.boolean "show_srm", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "theme", default: "classic", null: false
    t.index ["date"], name: "index_events_on_date", unique: true
  end

  create_table "packages", force: :cascade do |t|
    t.string "type", null: false
    t.float "volume", null: false
    t.string "unit", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["type", "volume", "unit"], name: "index_packages_on_type_and_volume_and_unit", unique: true
  end

  create_table "sensor_readings", force: :cascade do |t|
    t.integer "session_id", null: false
    t.integer "sensor_id", null: false
    t.float "reading_value", null: false
    t.datetime "recorded_at", null: false
    t.index ["sensor_id"], name: "index_sensor_readings_on_sensor_id"
    t.index ["session_id", "recorded_at"], name: "index_sensor_readings_on_session_id_and_recorded_at"
    t.index ["session_id"], name: "index_sensor_readings_on_session_id"
  end

  create_table "sensors", force: :cascade do |t|
    t.string "type", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.boolean "is_virtual", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_sensors_on_slug", unique: true
    t.index ["type"], name: "index_sensors_on_type"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "configuration_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "event_id"
    t.index ["configuration_id"], name: "index_sessions_on_configuration_id"
    t.index ["event_id"], name: "index_sessions_on_event_id", unique: true
    t.index ["status"], name: "index_sessions_on_status"
  end

  create_table "settings", force: :cascade do |t|
    t.integer "session_id", null: false
    t.string "key", null: false
    t.float "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id", "key"], name: "index_settings_on_session_id_and_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "control_actions", "actuators"
  add_foreign_key "control_actions", "sessions"
  add_foreign_key "drink_packages", "drinks"
  add_foreign_key "drink_packages", "events"
  add_foreign_key "drink_packages", "packages"
  add_foreign_key "drinks", "brands"
  add_foreign_key "sensor_readings", "sensors"
  add_foreign_key "sensor_readings", "sessions"
  add_foreign_key "sessions", "configurations"
  add_foreign_key "sessions", "events"
  add_foreign_key "settings", "sessions"
end
