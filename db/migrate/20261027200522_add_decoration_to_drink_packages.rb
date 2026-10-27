class AddDecorationToDrinkPackages < ActiveRecord::Migration[8.1]
  def change
    add_column :drink_packages, :emoji, :string
    add_column :drink_packages, :show_image, :boolean, default: true, null: false
  end
end
