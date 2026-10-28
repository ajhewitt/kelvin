class AddThemeToEvents < ActiveRecord::Migration[8.1]
  def change
    # The board's look for the event, one of Event::THEMES
    add_column :events, :theme, :string, default: "classic", null: false
  end
end
