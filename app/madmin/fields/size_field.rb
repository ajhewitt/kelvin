# A package's size as printed on it, an amount and one of Package::MEASURES, like 12 oz or 660 ml
class SizeField < Madmin::Field
  def to_param
    [:amount, :measure]
  end
end
