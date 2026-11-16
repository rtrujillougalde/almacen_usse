users = [
  { first_name: "Admin", last_name: "USSE", email: "admin@usse.local", role: :admin, password: "password" },
  { first_name: "Operador", last_name: "USSE", email: "operador@usse.local", role: :operador, password: "password" },
  { first_name: "Consulta", last_name: "USSE", email: "consulta@usse.local", role: :consulta, password: "password" }
]

users.each do |attrs|
  user = User.find_or_initialize_by(email: attrs[:email])
  user.first_name = attrs[:first_name]
  user.last_name = attrs[:last_name]
  user.role = attrs[:role]
  user.password = attrs[:password]
  user.password_confirmation = attrs[:password]
  user.save!
end

puts "Seeded users: #{User.pluck(:email).join(', ')} (password: password)"
