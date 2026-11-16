class User < ApplicationRecord
  # Warehouse app: no public self-registration. Admins create accounts in-app.
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  enum :role, {
    admin: "admin",
    operador: "operador",
    consulta: "consulta"
  }, validate: true

  ROLE_LABELS = {
    "admin" => "Administrador",
    "operador" => "Operador",
    "consulta" => "Consulta"
  }.freeze

  STAFF_PAGES = %w[inventario entradas compras salidas proyectos reportes proveedores].freeze

  ROLE_PAGES = {
    "admin" => STAFF_PAGES + %w[usuarios],
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
    "proveedores" => :proveedores_path,
    "usuarios" => :usuarios_path
  }.freeze

  validates :first_name, :last_name, presence: true, length: { maximum: 100 }
  validates :role, presence: true
  validate :keep_one_active_admin, on: :update

  # Deactivated accounts cannot sign in.
  def active_for_authentication?
    active?
  end

  def full_name
    [ first_name, last_name ].compact_blank.join(" ")
  end

  def can_access?(page)
    ROLE_PAGES.fetch(role, []).include?(page.to_s)
  end

  def allowed_pages
    ROLE_PAGES.fetch(role, [])
  end

  def first_allowed_page
    allowed_pages.first || "inventario"
  end

  private

  # Stops the last active admin from being deactivated or demoted.
  def keep_one_active_admin
    return unless will_save_change_to_role? || will_save_change_to_active?
    return unless attribute_in_database(:role) == "admin" && attribute_in_database(:active)
    return if admin? && active?
    return if User.where(role: "admin", active: true).where.not(id: id).exists?

    errors.add(:base, "Debe quedar al menos un administrador activo.")
  end
end
