namespace :users do
  desc "Create a regular (read-only) user. Usage: rails users:create USERNAME=alice PASSWORD=secret"
  task create: :environment do
    username = ENV.fetch("USERNAME") { abort "Usage: rails users:create USERNAME=... PASSWORD=..." }
    password = ENV.fetch("PASSWORD") { abort "Usage: rails users:create USERNAME=... PASSWORD=..." }

    user = User.create!(username: username, password: password, admin: false)
    puts "Created user: #{user.username}"
  end

  desc "Promote an existing user to admin. Usage: rails users:make_admin USERNAME=alice"
  task make_admin: :environment do
    username = ENV.fetch("USERNAME") { abort "Usage: rails users:make_admin USERNAME=..." }
    user = User.find_by!(username: username)
    user.update!(admin: true)
    puts "#{user.username} is now an admin."
  end
end
