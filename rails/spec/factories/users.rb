FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@usse.local" }
    first_name { "Prueba" }
    last_name { "Usuario" }
    password { "password" }
    password_confirmation { "password" }
    role { :consulta }
    active { true }

    trait :admin do
      role { :admin }
      sequence(:email) { |n| "admin#{n}@usse.local" }
    end

    trait :operador do
      role { :operador }
      sequence(:email) { |n| "operador#{n}@usse.local" }
    end

    trait :consulta do
      role { :consulta }
      sequence(:email) { |n| "consulta#{n}@usse.local" }
    end

    trait :inactive do
      active { false }
    end
  end
end
