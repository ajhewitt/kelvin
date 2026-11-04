class ConsolidatePubClassicThemes < ActiveRecord::Migration[8.1]
  # Pewter's font went to Frost, Letterpress was merged into Broadsheet, and Mahogany was dropped in favour of Tweed, so
  # events on those themes move to the theme that took their place. Rolling back leaves them there, as the old themes'
  # stylesheets are gone
  def change
    up_only do
      execute "UPDATE events SET theme = 'frost' WHERE theme = 'pewter'"
      execute "UPDATE events SET theme = 'broadsheet' WHERE theme = 'letterpress'"
      execute "UPDATE events SET theme = 'tweed' WHERE theme = 'mahogany'"
    end
  end
end
