require "rails_helper"
require "rake"

RSpec.describe "users:create" do
  before(:all) { Rails.application.load_tasks if Rake::Task.tasks.empty? }

  # Runs the task with the answers typed in, keeping its prompts out of the test output
  def run(answers)
    task = Rake::Task["users:create"]
    task.reenable
    $stdin = StringIO.new(answers)
    $stdout = StringIO.new
    task.invoke
  ensure
    $stdin = STDIN
    $stdout = STDOUT
  end

  it "adds a login from the answers typed in" do
    run("admin\nblack friday\nblack friday\n")

    expect(User.authenticate_by(username: "admin", password: "black friday")).to be_present
  end

  it "stops when the passwords don't match" do
    expect { run("admin\nblack friday\ncyber monday\n") }
      .to raise_error(SystemExit)
      .and output(/Password confirmation doesn't match/).to_stderr

    expect(User.count).to eq(0)
  end
end
