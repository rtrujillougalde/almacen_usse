FactoryBot.define do
  factory :proyecto do
    sequence(:c_c) { |n| 1000 + n }
    sequence(:nombre_obra) { |n| "Obra #{n}" }
    encargado { "Encargado" }
  end
end
