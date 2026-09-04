class StockPunta < ApplicationRecord
  self.table_name = "stock_puntas"
  self.primary_key = "id_punta"
  self.record_timestamps = false

  belongs_to :articulo, foreign_key: :id_articulo, primary_key: :id_articulo, inverse_of: :stock_puntas
  has_many :detalle_movimientos, foreign_key: :id_punta, inverse_of: :stock_punta, dependent: :nullify

  validates :longitud, presence: true, numericality: { greater_than: 0 }

  # A tip is unavailable once it appears on any salida detail line.
  scope :available, lambda {
    used_ids = DetalleMovimiento
      .joins(:movimiento)
      .where(movimientos: { tipo: Movimiento.tipos[:salida] })
      .where.not(id_punta: nil)
      .select(:id_punta)

    where.not(id_punta: used_ids)
  }
end
