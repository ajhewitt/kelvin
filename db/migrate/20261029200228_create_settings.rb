class CreateSettings < ActiveRecord::Migration[8.1]
  def change
    # What a session holds to, by key, like a serving session's draft temperature
    create_table :settings do |t|
      t.references :session, null: false, foreign_key: true, index: false
      t.string :key, null: false
      t.float :value, null: false

      t.timestamps
    end
    add_index :settings, [:session_id, :key], unique: true
  end
end
