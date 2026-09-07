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

    trait :compra do
      tipo { :compra }
      moneda { "MXN" }
      association :proveedor
    end
  end
end

