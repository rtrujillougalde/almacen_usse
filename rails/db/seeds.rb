users = [
  { first_name: "Admin", last_name: "USSE", email: "admin@usse.local", role: :admin, password: "Great123" },
  { first_name: "Operador", last_name: "USSE", email: "operador@usse.local", role: :operador, password: "Great123" },
  { first_name: "Consulta", last_name: "USSE", email: "consulta@usse.local", role: :consulta, password: "Great123" },
  { first_name: "Regina", last_name: "Trujillo", email: "regina@trujillo.local", role: :admin, password: "Great123" }
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

puts "Seeded users: #{User.pluck(:email).join(', ')} "
