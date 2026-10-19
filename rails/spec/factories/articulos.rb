FactoryBot.define do
  factory :articulo do
    sequence(:nombre) { |n| "Articulo #{n}" }
    tipo { :material }
    cantidad_en_stock { 10 }
    stock_minimo { 2 }
    unidad_medida { "pza" }
    precio_unitario { 100 }
    es_cable { false }
    association :proveedor_record, factory: :proveedor

    trait :cable do
      es_cable { true }
      unidad_medida { "m" }
      cantidad_en_stock { 0 }
    end

    trait :herramienta do
      tipo { :herramienta }
    end
  end
end
