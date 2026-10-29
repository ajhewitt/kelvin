# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Configurations
Configuration.find_or_create_by!(slug: "service") { |c| c.name = "Service Mode" }
Configuration.find_or_create_by!(slug: "brew_prep") { |c| c.name = "Brewing: Pre-Cool Reservoir" }
Configuration.find_or_create_by!(slug: "knockout") { |c| c.name = "Brewing: Wort Knockout" }
Configuration.find_or_create_by!(slug: "ferment") { |c| c.name = "Fermentation Guard" }

# Actuators (Using specific STI Classes)
UartActuator.find_or_create_by!(slug: "compressor_rpm") { |a| a.name = "Compressor Speed" }
PwmActuator.find_or_create_by!(slug: "pump_speed") { |a| a.name = "Coolant Pump Duty" }
LogicLevelActuator.find_or_create_by!(slug: "cask_on") { |a| a.name = "Cask Loop Valve" }

# Sensors (Using specific STI Classes)
OneWireSensor.find_or_create_by!(slug: "glycol_temp") { |s| s.name = "Glycol Reservoir Temp" }
ModbusReadSensor.find_or_create_by!(slug: "compressor_rpm") { |s| s.name = "Compressor Tachometer" }
VirtualSensor.find_or_create_by!(slug: "wort_temp") { |s| s.assign_attributes(name: "Calculated Output Wort Temp", is_virtual: true) }

# Tap list: last year's board, which also gives the board an event to show
keg = Keg.find_or_create_by!(volume: 5, unit: "gal")
cask = Cask.find_or_create_by!(volume: 4.5, unit: "imp_gal")
can_440ml = Can.find_or_create_by!(volume: 0.44, unit: "liter")
can_16oz = Can.find_or_create_by!(volume: 0.125, unit: "gal")
can_12oz = Can.find_or_create_by!(volume: 0.09375, unit: "gal")
bottle_660ml = Bottle.find_or_create_by!(volume: 0.66, unit: "liter")

st_mars = Brand.find_or_create_by!(name: "St. Mars of the Desert") { |b| b.country = "UK" }
cider_hill = Brand.find_or_create_by!(name: "Cider Hill Cellars") { |b| b.country = "USA" }

event = Event.find_or_create_by!(date: Date.new(2025, 11, 28)) do |e|
  e.name = "A Decade in the Making"
  e.tagline = "A Decade in the Making ’25"
end

# Each side in board order: brand, name, ABV, package, description
{
  cooperage: [
    [nil, "Harvey's Mild", 3.2, keg, "Based on the GBBF 2023 winning Mild."],
    [nil, "Retro Pride", 4.2, cask, "Fuller's London Pride clone based on 1970's recipe with corn and caramel sugar adjuncts."],
    [nil, "Coalbrook Porter", 5, keg, "Inspired by Fuller's London Porter."],
    [nil, "Kings Measure", 6.5, keg, "Winter Warmer (English strong ale)"],
    [nil, "Old Powderhouse", 12, keg, "The Mystic Brewery classic Wheat Wine made with 100% MA ingredients to 24° plato."],
    [nil, "Final Entroy", 15, keg, "The final blend of Mystic Brewery's Barrel-aged Uncarbonated “Still” Ale"]
  ],
  packaged: [
    [st_mars, "Civilization Machine", 3.7, can_440ml],
    [st_mars, "Smodfest Festbier Hell", 4.5, can_440ml],
    [st_mars, "Smoky Bockfest", 5.7, can_440ml],
    [st_mars, "Urchin", 6.1, bottle_660ml],
    [st_mars, "Biere de Miel", 7.2, bottle_660ml],
    [st_mars, "Tripel", 8, bottle_660ml],
    [st_mars, "Abbey Brune", 9.3, can_440ml],
    [st_mars, "Babamama", 8.4, can_440ml],
    [st_mars, "Barbapapa", 10, can_440ml],
    [cider_hill, "Strawberry Harvest", 8, can_16oz, "Hard Cider with Fresh Strawberry Juice"],
    [cider_hill, "Winter", 12.5, can_12oz, "Bourbon Barrel-aged Frost Cider."]
  ]
}.each_value do |side|
  side.each.with_index(1) do |(brand, name, abv, package, description), position|
    drink = Drink.find_or_create_by!(brand: brand, name: name) do |d|
      d.abv = abv
      d.description = description
    end
    event.drink_packages.find_or_create_by!(drink: drink, package: package) { |item| item.position = position }
  end
end
