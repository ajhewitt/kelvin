module BoardsHelper
  # "3.2%" or "10%"
  def abv_label(drink)
    "#{number_with_precision(drink.abv, precision: 2, strip_insignificant_zeros: true)}%" if drink.abv
  end
end
