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

ActiveRecord::Schema[8.1].define(version: 2026_06_14_000001) do
  create_table "actuators", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_actuators_on_slug", unique: true
    t.index ["type"], name: "index_actuators_on_type"
  end

  create_table "configurations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_configurations_on_slug", unique: true
  end

  create_table "control_actions", force: :cascade do |t|
    t.string "action_value", null: false
    t.integer "actuator_id", null: false
    t.datetime "executed_at", null: false
    t.integer "session_id", null: false
    t.index ["actuator_id"], name: "index_control_actions_on_actuator_id"
    t.index ["session_id"], name: "index_control_actions_on_session_id"
  end

  create_table "sensor_readings", force: :cascade do |t|
    t.float "reading_value", null: false
    t.datetime "recorded_at", null: false
    t.integer "sensor_id", null: false
    t.integer "session_id", null: false
    t.index ["sensor_id"], name: "index_sensor_readings_on_sensor_id"
    t.index ["session_id", "recorded_at"], name: "index_sensor_readings_on_session_id_and_recorded_at"
    t.index ["session_id"], name: "index_sensor_readings_on_session_id"
  end

  create_table "sensors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_virtual", default: false, null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_sensors_on_slug", unique: true
    t.index ["type"], name: "index_sensors_on_type"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "configuration_id", null: false
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["configuration_id"], name: "index_sessions_on_configuration_id"
    t.index ["status"], name: "index_sessions_on_status"
  end

  add_foreign_key "control_actions", "actuators"
  add_foreign_key "control_actions", "sessions"
  add_foreign_key "sensor_readings", "sensors"
  add_foreign_key "sensor_readings", "sessions"
  add_foreign_key "sessions", "configurations"
end
