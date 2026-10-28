require "rails_helper"

RSpec.describe "Logins", type: :request do
  let!(:user) { User.create!(username: "admin", password: "black friday") }

  it "sends visitors to the admin screens to log in, then on to where they were going" do
    event = Event.create!(name: "Black Friday", date: Date.new(2026, 11, 27))

    get madmin_drinks_path
    expect(response).to redirect_to(login_path)

    post login_path, params: {username: "Admin", password: "black friday"}
    expect(response).to redirect_to(madmin_drinks_path)

    get madmin_root_path
    expect(response).to redirect_to(madmin_event_drink_packages_path(event))
  end

  it "turns away a wrong password" do
    post login_path, params: {username: "admin", password: "cyber monday"}

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Wrong username or password.")

    get madmin_drinks_path
    expect(response).to redirect_to(login_path)
  end

  it "logs out" do
    log_in(user)

    delete login_path
    expect(response).to redirect_to(login_path)

    get madmin_drinks_path
    expect(response).to redirect_to(login_path)
  end

  it "ends a login when its user is deleted" do
    other = User.create!(username: "bar", password: "black friday")
    log_in(other)

    other.destroy!

    get madmin_drinks_path
    expect(response).to redirect_to(login_path)
  end

  it "slows down guessing" do
    # The test environment has no cache to count tries in, so this stands in for a full count
    allow(LoginsController.cache_store).to receive(:increment).and_return(11)

    post login_path, params: {username: "admin", password: "black friday"}

    expect(response).to redirect_to(login_path)
    expect(flash[:alert]).to start_with("Too many tries")
  end

  it "says how to add the first login" do
    get login_path
    expect(response.body).not_to include("bin/rails users:create")

    User.delete_all
    get login_path
    expect(response.body).to include("There are no logins yet")
  end

  it "keeps the board public" do
    get root_path
    expect(response).to have_http_status(:ok)

    get rails_health_check_path
    expect(response).to have_http_status(:ok)
  end
end
