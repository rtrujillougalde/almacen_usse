class EppMovimiento < ApplicationRecord
  self.record_timestamps = false

  belongs_to :trabajador, foreign_key: :id_trabajador, inverse_of: :epp_movimientos

  enum :tipo_de_movimiento, {
    entrega_primera_vez: "entrega_primera_vez",
    reemplazo_por_desgaste: "reemplazo_por_desgaste",
    reemplazo_por_perdida: "reemplazo_por_perdida"
  }, validate: true

  has_one_attached :doc_firma

  validates :fecha_y_hora, presence: true
  validate :doc_firma_is_pdf_or_png

  private

  def doc_firma_is_pdf_or_png
    return unless doc_firma.attached?
    return if Documento::ALLOWED_CONTENT_TYPES.include?(doc_firma.blob.content_type)

    errors.add(:doc_firma, "debe ser PDF o PNG")
  end
end
