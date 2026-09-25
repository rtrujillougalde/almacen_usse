class Articulo < ApplicationRecord
  self.table_name = "articulos"
  self.primary_key = "id_articulo"
  self.record_timestamps = false

  CATEGORIAS = %w[
    albañileria aire_acondicionado aislantes almacen_dormitorios alumbrado baterias c_d cables
    calentadores canalizaciones charolas cinchos conductor contactos contactos_regulados
    control_almacen control_acceso datos eléctrico equipo_medición equipo_protección fibra_óptica
    fuse_panel fusibles gasolina general herramienta herrería interruptores kit_cursos limpieza
    miscelaneos motores papelería pintura planta_emergencia plomeria racks referencia registros
    regletas seguridad soportes tablaroca tableros tierras tornilleria zapatas
  ].freeze

  # Association name must differ from the FK column `proveedor` (integer),
  # otherwise assign_attributes(proveedor: "1") raises AssociationTypeMismatch.
  belongs_to :proveedor_record,
             class_name: "Proveedor",
             foreign_key: :proveedor,
             primary_key: :id_proveedor,
             optional: true,
             inverse_of: :articulos

  has_many :stock_puntas, foreign_key: :id_articulo, inverse_of: :articulo, dependent: :destroy
  has_many :detalle_movimientos, foreign_key: :id_articulo, inverse_of: :articulo, dependent: :restrict_with_exception

  enum :tipo, { material: "material", herramienta: "herramienta" }, validate: true
  enum :almacen, {
    oficina: "oficina",
    uno: "uno",
    dos: "dos",
    tres: "tres",
    dormitorios: "dormitorios"
  }, validate: { allow_nil: true }
  enum :ubicacion, {
    nivel_1: "nivel_1",
    nivel_2: "nivel_2",
    planta_baja: "planta_baja",
    estante_compras: "estante_compras"
  }, validate: { allow_nil: true }

  validates :nombre, presence: true
  validates :categoria, inclusion: { in: CATEGORIAS }, allow_nil: true

  # The inventario filters offer an "everything" option; selecting it is the
  # same as not filtering, which is also what a blank param means.
  ALL_CATEGORIAS = "Todas".freeze
  ALL_TIPOS = "Todos".freeze

  scope :alphabetical, -> { order(:nombre) }

  scope :with_categoria, ->(value) {
    where(categoria: value) if value.present? && value != ALL_CATEGORIAS
  }

  scope :with_tipo, ->(value) {
    where(tipo: value) if value.present? && value != ALL_TIPOS
  }

  # % and _ are LIKE wildcards, so an unescaped search for "50%" matches every
  # articulo starting with 50, and "a_b" matches "axb".
  scope :nombre_matching, ->(term) {
    if term.present?
      where("LOWER(nombre) LIKE ?", "%#{sanitize_sql_like(term.to_s.downcase)}%")
    end
  }

  def low_stock?
    return false if cantidad_en_stock.nil? || stock_minimo.nil?

    cantidad_en_stock < stock_minimo
  end

  # cantidad_en_stock is a cache, and only cables with tracked puntas can have
  # it recomputed: their stock is the length still on the shelf. Everything
  # else carries an opening balance from before the movement history existed,
  # so the stored figure is the only truth there is.
  def derivable_stock?
    es_cable? && stock_puntas.exists?
  end

  def derived_stock
    stock_puntas.merge(StockPunta.available).sum(:longitud)
  end

  # Positive when the cache is behind the puntas, nil when nothing to compare.
  def stock_drift
    return nil unless derivable_stock?

    derived_stock - cantidad_en_stock.to_d
  end

  def recalculate_stock!
    return false unless derivable_stock?

    update!(cantidad_en_stock: derived_stock)
  end
end
