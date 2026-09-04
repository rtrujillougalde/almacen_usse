FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    sequence(:email) { |n| "user#{n}@usse.local" }
    password { "password" }
    password_confirmation { "password" }
    role { :consulta }

    trait :admin do
      role { :admin }
      sequence(:username) { |n| "admin#{n}" }
      sequence(:email) { |n| "admin#{n}@usse.local" }
    end

    trait :operador do
      role { :operador }
      sequence(:username) { |n| "operador#{n}" }
      sequence(:email) { |n| "operador#{n}@usse.local" }
    end

    trait :consulta do
      role { :consulta }
      sequence(:username) { |n| "consulta#{n}" }
      sequence(:email) { |n| "consulta#{n}@usse.local" }
    end
  end
end
