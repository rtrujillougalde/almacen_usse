users = [
  { username: "admin", email: "admin@usse.local", role: :admin, password: "password" },
  { username: "operador", email: "operador@usse.local", role: :operador, password: "password" },
  { username: "consulta", email: "consulta@usse.local", role: :consulta, password: "password" }
]

users.each do |attrs|
  user = User.find_or_initialize_by(username: attrs[:username])
  user.email = attrs[:email]
  user.role = attrs[:role]
  user.password = attrs[:password]
  user.password_confirmation = attrs[:password]
  user.save!
end

puts "Seeded users: #{User.pluck(:username).join(', ')} (password: password)"
