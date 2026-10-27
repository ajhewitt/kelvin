class CreateTapList < ActiveRecord::Migration[8.1]
  def change
    create_table :brands do |t|
      t.string :name, null: false
      t.string :country
      t.timestamps
    end
    add_index :brands, :name, unique: true

    create_table :drinks do |t|
      t.references :brand, foreign_key: true # nil for the house's own drinks
      t.string :name, null: false
      t.text :description
      t.decimal :abv, precision: 5, scale: 2
      t.integer :ibu
      t.decimal :srm, precision: 4, scale: 1
      t.timestamps
    end

    create_table :packages do |t|
      t.string :type, null: false # STI column: Keg, Cask, Bottle or Can
      t.float :volume, null: false
      t.string :unit, null: false
      t.timestamps
    end
    add_index :packages, [:type, :volume, :unit], unique: true

    create_table :events do |t|
      t.date :date, null: false
      t.string :name, null: false
      t.string :tagline
      t.text :description
      t.timestamps
    end
    add_index :events, :date, unique: true

    create_table :drink_packages do |t|
      t.references :event, null: false, foreign_key: true, index: false
      t.references :drink, null: false, foreign_key: true
      t.references :package, null: false, foreign_key: true
      t.integer :position, null: false
      t.timestamps
    end
    add_index :drink_packages, [:event_id, :drink_id, :package_id], unique: true
  end
end
