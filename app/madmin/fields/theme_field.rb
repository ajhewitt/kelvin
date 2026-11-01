# An event's theme for the board, picked by name with a line on how it looks, in the gallery's groups
class ThemeField < Madmin::Field
  # Every theme but the easter eggs, unless the event already uses one, which saving the form keeps. It
  # goes in the last group, where its card shows in the gallery
  def options_for_select(record)
    groups = Event::THEME_GROUPS.to_a
    egg = Event::EASTER_EGGS.slice(record.theme)
    groups[-1] = [groups[-1][0], groups[-1][1].merge(egg)] if egg.any?
    groups.map { |group, themes| [group, themes.map { |theme, description| ["#{theme.titleize}: #{description}", theme] }] }
  end
end
