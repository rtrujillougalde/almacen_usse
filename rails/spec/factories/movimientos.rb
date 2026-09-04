FactoryBot.define do
  factory :movimiento do
    association :proyecto
    tipo { :entrada }
    responsable { "tester" }
    fecha_hora { Time.current }
    observaciones { nil }

    trait :salida do
      tipo { :salida }
    end
  end
end
