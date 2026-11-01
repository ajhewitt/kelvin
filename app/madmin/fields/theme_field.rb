# An event's theme for the board, picked by name with a line on how it looks
class ThemeField < Madmin::Field
  # Every theme but the easter eggs, unless the event already uses one, which saving the form keeps
  def options_for_select(record)
    Event::THEMES.merge(Event::EASTER_EGGS.slice(record.theme)).map { |theme, description| ["#{theme.titleize}: #{description}", theme] }
  end
end
