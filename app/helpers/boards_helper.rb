module BoardsHelper
  # "6.5%", "76 IBU" or "12 SRM", or nothing when the drink has no value for the stat
  def stat_label(drink, stat)
    value = drink.public_send(stat)
    return if value.nil?

    number = number_with_precision(value, precision: 2, strip_insignificant_zeros: true)
    (stat == :abv) ? "#{number}%" : "#{number} #{stat.upcase}"
  end
end
