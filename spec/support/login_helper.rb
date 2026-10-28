module LoginHelper
  def log_in(user = User.create!(username: "admin", password: "black friday"))
    post login_path, params: {username: user.username, password: user.password}
    user
  end
end

RSpec.configure do |config|
  config.include LoginHelper, type: :request
end
