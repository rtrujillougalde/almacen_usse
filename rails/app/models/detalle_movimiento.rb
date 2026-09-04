class DetalleMovimiento < ApplicationRecord
  self.table_name = "detalle_movimientos"
  self.primary_key = "id_detalle"
  self.record_timestamps = false

  belongs_to :movimiento, foreign_key: :id_movimiento, primary_key: :id_movimiento, inverse_of: :detalle_movimientos
  belongs_to :articulo, foreign_key: :id_articulo, primary_key: :id_articulo, inverse_of: :detalle_movimientos
  belongs_to :stock_punta, foreign_key: :id_punta, primary_key: :id_punta, optional: true, inverse_of: :detalle_movimientos

  validates :cantidad, presence: true, numericality: { greater_than: 0 }
end
