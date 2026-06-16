class CreateKelvinBackend < ActiveRecord::Migration[8.1]
  def change
    create_table :configurations do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :description
      t.timestamps
    end
    add_index :configurations, :slug, unique: true

    create_table :sessions do |t|
      t.references :configuration, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.datetime :started_at
      t.datetime :ended_at
      t.timestamps
    end
    add_index :sessions, :status

    create_table :actuators do |t|
      t.string :type, null: false            # STI Column (e.g., "UartActuator")
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps
    end
    add_index :actuators, :slug, unique: true
    add_index :actuators, :type

    create_table :sensors do |t|
      t.string :type, null: false            # STI Column (e.g., "OneWireSensor")
      t.string :name, null: false
      t.string :slug, null: false
      t.boolean :is_virtual, default: false, null: false
      t.timestamps
    end
    add_index :sensors, :slug, unique: true
    add_index :sensors, :type

    create_table :control_actions do |t|
      t.references :session, null: false, foreign_key: true
      t.references :actuator, null: false, foreign_key: true
      t.string :action_value, null: false
      t.datetime :executed_at, null: false
    end

    create_table :sensor_readings do |t|
      t.references :session, null: false, foreign_key: true
      t.references :sensor, null: false, foreign_key: true
      t.float :reading_value, null: false
      t.datetime :recorded_at, null: false
    end
    add_index :sensor_readings, [:session_id, :recorded_at]
  end
end
