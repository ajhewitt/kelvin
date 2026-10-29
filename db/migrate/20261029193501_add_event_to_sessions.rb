class AddEventToSessions < ActiveRecord::Migration[8.1]
  def change
    # The event a serving session is for, one session to an event
    add_reference :sessions, :event, foreign_key: true, index: {unique: true}
  end
end
