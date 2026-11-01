class MoveHopGardenEventsToGrandPlace < ActiveRecord::Migration[8.1]
  # Grand Place replaced the Hop Garden theme, so events still on Hop Garden move across. Rolling
  # back leaves them there, as Hop Garden's stylesheet is gone
  def change
    up_only do
      execute "UPDATE events SET theme = 'grand_place' WHERE theme = 'hop_garden'"
    end
  end
end
