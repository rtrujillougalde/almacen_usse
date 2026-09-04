FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    sequence(:email) { |n| "user#{n}@usse.local" }
    password { "password" }
    password_confirmation { "password" }
    role { :consulta }

    trait :admin do
      username { "admin" }
      email { "admin@usse.local" }
      role { :admin }
    end

    trait :operador do
      username { "operador" }
      email { "operador@usse.local" }
      role { :operador }
    end

    trait :consulta do
      username { "consulta" }
      email { "consulta@usse.local" }
      role { :consulta }
    end
  end
end
