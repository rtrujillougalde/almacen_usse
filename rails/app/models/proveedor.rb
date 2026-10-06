class Proveedor < ApplicationRecord
  self.table_name = "proveedores"
  self.primary_key = "id_proveedor"
  self.record_timestamps = false

  has_many :articulos, foreign_key: :proveedor, inverse_of: :proveedor_record, dependent: :restrict_with_exception
  has_many :movimientos, foreign_key: :id_proveedor, inverse_of: :proveedor, dependent: :restrict_with_exception

  # One current supplier-wide minimum. Zone or product exceptions stay in notas.
  enum :entrega_estado, {
    desconocida: "desconocida",
    ofrecida: "ofrecida",
    no_ofrecida: "no_ofrecida"
  }, default: :desconocida, validate: true

  validates :nombre, presence: true
  validates :entrega_monto_minimo, numericality: { greater_than_or_equal_to: 0 }, if: :ofrecida?
  validates :entrega_moneda, inclusion: { in: Movimiento::MONEDAS }, if: :ofrecida?

  scope :alphabetical, -> { order(:nombre) }

  before_validation :clear_entrega_unless_offered
  before_create :assign_id_proveedor

  def entrega_resumen
    return "Desconocida" if desconocida?
    return "No ofrece" if no_ofrecida?
    return "Sin mínimo (#{entrega_moneda})" if entrega_monto_minimo.to_d.zero?

    "Desde $#{format('%.2f', entrega_monto_minimo)} #{entrega_moneda}"
  end

  private

  def clear_entrega_unless_offered
    return if ofrecida?

    self.entrega_monto_minimo = nil
    self.entrega_moneda = nil
  end

  def assign_id_proveedor
    self.id_proveedor ||= (self.class.maximum(:id_proveedor) || 0) + 1
  end
end
