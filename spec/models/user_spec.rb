require "rails_helper"

RSpec.describe User, type: :model do
  it "logs in with a username that ignores case and surrounding spaces" do
    User.create!(username: " Admin ", password: "black friday")

    expect(User.authenticate_by(username: "admin", password: "black friday")).to be_present
    expect(User.authenticate_by(username: "ADMIN", password: "wrong")).to be_nil
  end

  it "requires a unique username and a password of at least 8 characters" do
    User.create!(username: "admin", password: "black friday")

    expect(User.new(username: "Admin", password: "black friday")).not_to be_valid
    expect(User.new(username: "bar", password: "short")).not_to be_valid
    expect(User.new(username: "bar")).not_to be_valid
  end

  it "keeps its password when saved with a blank one" do
    user = User.create!(username: "admin", password: "black friday")

    user.update!(password: "")

    expect(user.reload.authenticate("black friday")).to eq(user)
  end

  it "ends its logins when the password changes" do
    user = User.create!(username: "admin", password: "black friday")
    token = user.generate_token_for(:login)

    expect(User.find_by_token_for(:login, token)).to eq(user)

    user.update!(password: "cyber monday")
    expect(User.find_by_token_for(:login, token)).to be_nil
  end

  it "can't delete the last user" do
    first = User.create!(username: "admin", password: "black friday")
    second = User.create!(username: "bar", password: "black friday")

    expect(second.destroy).to be_truthy
    expect(first.destroy).to be(false)
    expect(first.errors[:base]).to eq(["The last user can't be deleted"])
  end
end
