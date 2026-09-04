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

  belongs_to :proveedor,
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

  def low_stock?
    return false if cantidad_en_stock.nil? || stock_minimo.nil?

    cantidad_en_stock < stock_minimo
  end
end
