module SettingsHelper
  # A setting's value, or a reading of it: "38°F" for a temperature, whose key ends in _temp like its
  # sensor's slug, and otherwise the number
  def setting_value(setting, value = setting.value)
    number = number_with_precision(value, precision: 1, strip_insignificant_zeros: true)
    setting.key.end_with?("_temp") ? "#{number}°F" : number
  end
end
