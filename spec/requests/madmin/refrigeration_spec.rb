require "rails_helper"

RSpec.describe "Refrigeration in the admin", type: :request do
  let(:service) { Configuration.create!(name: "Service Mode", slug: "service") }
  let(:session) { Session.create!(configuration: service).tap(&:start) }
  let(:glycol) { OneWireSensor.create!(name: "Glycol Reservoir Temp", slug: "glycol_temp") }
  let(:wort) { VirtualSensor.create!(name: "Calculated Output Wort Temp", slug: "wort_temp", is_virtual: true) }
  let(:pump) { PwmActuator.create!(name: "Coolant Pump Duty", slug: "pump_speed") }

  before { log_in }

  def page
    Nokogiri::HTML(response.body)
  end

  def read(sensor, value, minute)
    session.sensor_readings.create!(sensor: sensor, reading_value: value, recorded_at: Time.utc(2026, 11, 27, 18, minute))
  end

  {
    "configurations" => -> { service },
    "sessions" => -> { session },
    "sensors" => -> { glycol },
    "actuators" => -> { pump }
  }.each do |name, record|
    it "lists, shows and edits #{name}" do
      record = instance_exec(&record)

      ["/madmin/#{name}", "/madmin/#{name}/new", "/madmin/#{name}/#{record.id}", "/madmin/#{name}/#{record.id}/edit"].each do |path|
        get path
        expect(response).to have_http_status(:ok), "#{path} gave #{response.status}"
      end
    end
  end

  it "adds a sensor of a given type" do
    post madmin_sensors_path, params: {sensor: {type: "OneWireSensor", name: "Keg Fridge Temp", slug: "keg_temp"}}

    expect(Sensor.find_by!(slug: "keg_temp")).to be_a(OneWireSensor)
  end

  it "asks again for a sensor's type when none is picked" do
    post madmin_sensors_path, params: {sensor: {type: "", name: "Keg Fridge Temp", slug: "keg_temp"}}

    expect(response).to have_http_status(:unprocessable_content)
    expect(Sensor.exists?(slug: "keg_temp")).to be(false)
  end

  it "keeps the logs to looking, newest first" do
    read(glycol, -1.5, 0)
    read(glycol, -1.2, 1)
    session.control_actions.create!(actuator: pump, action_value: "60", executed_at: Time.utc(2026, 11, 27, 18))

    get madmin_sensor_readings_path
    expect(page.css("tbody tr td:nth-child(3)").map { |cell| cell.text.strip }).to eq(["-1.2", "-1.5"])
    expect(page.at_css("a[href='/madmin/sensor_readings/new']")).to be_nil

    get madmin_sensor_reading_path(SensorReading.first)
    expect(response).to have_http_status(:ok)
    expect(page.at_css("a[href$='/edit']")).to be_nil

    get madmin_control_actions_path
    expect(response.body).to include("Coolant Pump Duty")
  end

  it "shows times in the server's time zone, to the second" do
    read(glycol, -1.5, 1)

    Time.use_zone("America/New_York") { get madmin_sensor_readings_path }

    expect(page.at_css("tbody tr td").text.strip).to eq("Fri 27 Nov 2026, 13:01:00")
  end

  it "has no way to change a log" do
    reading = read(glycol, -1.5, 0)

    get "/madmin/sensor_readings/new"
    expect(response).to have_http_status(:not_found)

    patch "/madmin/sensor_readings/#{reading.id}", params: {sensor_reading: {reading_value: 99}}
    expect(response).to have_http_status(:not_found)
    expect(reading.reload.reading_value).to eq(-1.5)
  end

  it "links a sensor to its own readings" do
    read(glycol, -1.5, 0)
    read(wort, 18.2, 0)

    get madmin_sensor_path(wort)
    readings_link = page.css("a").find { |link| link.text == "Readings" }["href"]

    get readings_link
    expect(page.css("tbody tr").size).to eq(1)
    expect(page.at_css("tbody").text).to include("Calculated Output Wort Temp")
  end

  it "links a session to its readings and control actions" do
    get madmin_session_path(session)

    expect(page.css("a").map(&:text)).to include("Sensor readings", "Control actions")
  end

  it "groups the sidebar into sections" do
    get madmin_sensors_path

    expect(page.css("#sidebar nav h4").map(&:text)).to eq(["Tap list", "Refrigeration", "Logs"])
    expect(page.css("#sidebar nav a").map(&:text)).to eq([
      "Current list", "Events", "Drinks", "Brands", "Packages",
      "Configurations", "Sessions", "Sensors", "Actuators",
      "Sensor readings", "Control actions"
    ])
    expect(page.css("#sidebar footer a").map(&:text)).to eq(["Board", "Users"])
  end
end
