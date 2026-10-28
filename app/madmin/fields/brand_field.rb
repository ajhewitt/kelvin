# A drink's brand, left blank for the house's own drinks
class BrandField < Madmin::Fields::BelongsTo
  def options_for_select(record)
    Brand.order(:name).pluck(:name, :id)
  end
end
