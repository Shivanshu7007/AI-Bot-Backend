# db/seeds.rb

admin_email = "admin@example.com"
admin_password = "Admin@123"

admin = AdminUser.find_or_create_by!(email: admin_email) do |a|
  a.password = admin_password
  a.password_confirmation = admin_password
end

puts "✅ Admin ensured: #{admin.email}"