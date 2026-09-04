FactoryBot.define do
  factory :detalle_movimiento do
    association :movimiento
    association :articulo
    cantidad { 1 }
    stock_punta { nil }
  end
end
