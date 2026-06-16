# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

require_dependency 'actuator'
require_dependency 'sensor'

# Configurations
Configuration.create!(name: "Service Mode", slug: "service")
Configuration.create!(name: "Brewing: Pre-Cool Reservoir", slug: "brew_prep")
Configuration.create!(name: "Brewing: Wort Knockout", slug: "knockout")
Configuration.create!(name: "Fermentation Guard", slug: "ferment")

# Actuators (Using specific STI Classes)
UartActuator.create!(name: "Compressor Speed", slug: "compressor_rpm")
PwmActuator.create!(name: "Coolant Pump Duty", slug: "pump_speed")
LogicLevelActuator.create!(name: "Cask Loop Valve", slug: "cask_on")

# Sensors (Using specific STI Classes)
OneWireSensor.create!(name: "Glycol Reservoir Temp", slug: "glycol_temp", is_virtual: false)
ModbusReadSensor.create!(name: "Compressor Tachometer", slug: "compressor_rpm", is_virtual: false)
VirtualSensor.create!(name: "Calculated Output Wort Temp", slug: "wort_temp", is_virtual: true)
