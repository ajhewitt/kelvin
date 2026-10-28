# An event's theme for the board, picked by name with a line on how it looks
class ThemeField < Madmin::Field
  def options_for_select(record)
    Event::THEMES.map { |theme, description| ["#{theme.titleize}: #{description}", theme] }
  end
end
