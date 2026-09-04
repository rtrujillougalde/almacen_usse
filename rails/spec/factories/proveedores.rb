FactoryBot.define do
  factory :proveedor do
    sequence(:nombre) { |n| "Proveedor #{n}" }
    telefono { "555-0000" }
    email { "proveedor@example.com" }
    contacto { "Contacto" }
    direccion { "Calle 1" }
    pagina_web { "https://example.com" }
    notas { "Notas" }
  end
end
