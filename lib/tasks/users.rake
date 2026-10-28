namespace :users do
  desc "Add a login for the admin screens, asking for its username and password"
  task create: :environment do
    require "io/console"

    # Passwords aren't echoed when typed at a terminal
    ask = lambda do |prompt, secret: false|
      print prompt
      answer = (secret && $stdin.tty?) ? $stdin.noecho(&:gets).tap { puts } : $stdin.gets
      answer.to_s.chomp
    end

    user = User.new(username: ask.call("Username: "))
    user.password = ask.call("Password: ", secret: true)
    user.password_confirmation = ask.call("Password again: ", secret: true)

    if user.save
      puts "Added #{user.username}. Log in at /login"
    else
      abort user.errors.full_messages.to_sentence
    end
  end
end
