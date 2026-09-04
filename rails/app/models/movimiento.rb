class Movimiento < ApplicationRecord
  self.table_name = "movimientos"
  self.primary_key = "id_movimiento"
  self.record_timestamps = false

  belongs_to :proyecto, foreign_key: :id_proyecto, primary_key: :id_proyecto, optional: true, inverse_of: :movimientos
  has_many :detalle_movimientos, foreign_key: :id_movimiento, inverse_of: :movimiento, dependent: :destroy

  enum :tipo, { entrada: "entrada", salida: "salida" }, validate: true

  validates :tipo, presence: true

  before_validation :set_fecha_hora, on: :create

  private

  def set_fecha_hora
    self.fecha_hora ||= Time.current
  end
end
