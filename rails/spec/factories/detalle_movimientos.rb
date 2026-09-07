FactoryBot.define do
  factory :detalle_movimiento do
    association :movimiento
    association :articulo
    cantidad { 1 }
    precio_unitario { nil }
    stock_punta { nil }
  end
end
