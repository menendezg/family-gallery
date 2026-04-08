# Creates an admin user. Change the credentials before running in production.
# Run with: rails db:seed
admin = User.find_or_initialize_by(username: "admin")
admin.password = "changeme123"
admin.admin = true
admin.save!

puts "Admin user ready: #{admin.username}"
