FactoryBot.define do
  factory :stock_punta do
    association :articulo, factory: [ :articulo, :cable ]
    sequence(:nombre_punta) { |n| "Punta #{n}" }
    longitud { 25.5 }
    color { "negro" }
  end
end
