class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    # Logins for the admin screens; the board itself needs none
    create_table :users do |t|
      t.string :username, null: false, index: {unique: true}
      t.string :password_digest, null: false
      t.timestamps
    end
  end
end
