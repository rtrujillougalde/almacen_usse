class User < ApplicationRecord
  # Warehouse app: no public self-registration.
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  enum :role, {
    admin: "admin",
    operador: "operador",
    consulta: "consulta"
  }, validate: true

  STAFF_PAGES = %w[inventario entradas compras salidas proyectos reportes proveedores].freeze

  ROLE_PAGES = {
    "admin" => STAFF_PAGES,
    "operador" => STAFF_PAGES,
    "consulta" => %w[inventario reportes]
  }.freeze

  PAGE_PATHS = {
    "inventario" => :inventario_path,
    "entradas" => :entradas_path,
    "compras" => :compras_path,
    "salidas" => :salidas_path,
    "proyectos" => :proyectos_path,
    "reportes" => :reportes_path,
    "proveedores" => :proveedores_path
  }.freeze

  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :role, presence: true

  def can_access?(page)
    ROLE_PAGES.fetch(role, []).include?(page.to_s)
  end

  def allowed_pages
    ROLE_PAGES.fetch(role, [])
  end

  def first_allowed_page
    allowed_pages.first || "inventario"
  end
end
