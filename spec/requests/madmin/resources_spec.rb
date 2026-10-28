require "rails_helper"

RSpec.describe "Admin screens", type: :request do
  let!(:user) { log_in }
  let(:event) { Event.create!(name: "Black Friday", date: Date.new(2026, 11, 27)) }
  let(:st_mars) { Brand.create!(name: "St. Mars of the Desert", country: "UK") }
  let(:drink) { Drink.create!(name: "Urchin", abv: 6.1, brand: st_mars) }
  let(:package) { Bottle.create!(volume: 0.66, unit: "liter") }

  def page
    Nokogiri::HTML(response.body)
  end

  {
    "events" => -> { event },
    "drinks" => -> { drink },
    "brands" => -> { st_mars },
    "packages" => -> { package },
    "users" => -> { user }
  }.each do |name, record|
    it "lists, shows and edits #{name}" do
      record = instance_exec(&record)

      ["/madmin/#{name}", "/madmin/#{name}/new", "/madmin/#{name}/#{record.id}", "/madmin/#{name}/#{record.id}/edit"].each do |path|
        get path
        expect(response).to have_http_status(:ok), "#{path} gave #{response.status}"
      end
    end
  end

  it "adds an event, with the stats it shows" do
    post madmin_events_path, params: {event: {name: "Black Friday", date: "2026-11-27", tagline: "Hop Forward ’26", show_abv: "1", show_ibu: "1", show_srm: "0"}}

    event = Event.sole
    expect(response).to redirect_to(madmin_event_path(event))
    expect(event.stats).to eq([:ibu, :abv])
  end

  it "adds a house drink by leaving out the brand" do
    get new_madmin_drink_path
    expect(page.at_css("select#drink_brand_id option").text).to eq("House")

    post madmin_drinks_path, params: {drink: {name: "Orange Dinosaur", brand_id: "", abv: "8", ibu: "76"}}

    expect(Drink.sole).to have_attributes(name: "Orange Dinosaur", brand: nil, ibu: 76)
  end

  it "copies a drink as a new brew, image and all" do
    drink.image.attach(io: file_fixture("drink.png").open, filename: "drink.png")

    post copy_madmin_drink_path(drink)

    copy = Drink.last
    expect(response).to redirect_to(edit_madmin_drink_path(copy))
    expect(copy).to have_attributes(name: "Urchin", abv: 6.1, brand: st_mars)
    expect(copy.image.blob).to eq(drink.image.blob)
    expect(copy).not_to eq(drink)
  end

  it "removes a drink's image and goes back to its form" do
    drink.image.attach(io: file_fixture("drink.png").open, filename: "drink.png")

    delete madmin_active_storage_attachment_path(drink.image.attachment), headers: {"Referer" => edit_madmin_drink_url(drink)}

    expect(response).to redirect_to(edit_madmin_drink_url(drink))
    expect(drink.reload.image).not_to be_attached
  end

  it "takes a package size as printed" do
    post madmin_packages_path, params: {package: {type: "Can", amount: "16", measure: "oz"}}

    can = Package.sole
    expect(can).to be_a(Can)
    expect([can.volume, can.unit, can.to_s]).to eq([0.125, "gal", "Can 16 oz"])
  end

  it "won't delete a package that's on a list" do
    event.drink_packages.create!(drink: drink, package: package)

    delete madmin_package_path(package)

    expect(Package.exists?(package.id)).to be(true)
    expect(flash[:alert]).to be_present
  end

  it "adds a user" do
    post madmin_users_path, params: {user: {username: "bar", password: "black friday", password_confirmation: "black friday"}}

    expect(User.authenticate_by(username: "bar", password: "black friday")).to be_present
  end

  it "keeps you logged in after changing your own password" do
    patch madmin_user_path(user), params: {user: {username: "admin", password: "cyber monday", password_confirmation: "cyber monday"}}
    expect(user.reload.authenticate("cyber monday")).to eq(user)

    get madmin_drinks_path
    expect(response).to have_http_status(:ok)
  end

  it "won't let you delete yourself" do
    User.create!(username: "bar", password: "black friday")

    delete madmin_user_path(user)

    expect(User.exists?(user.id)).to be(true)
    expect(flash[:alert]).to eq("You can't delete yourself")
  end
end
