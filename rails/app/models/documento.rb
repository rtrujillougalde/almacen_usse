class Documento < ApplicationRecord
  self.record_timestamps = false

  FILE_FIELDS = %i[ine rfc nss csf certificado_medico antidoping dc3].freeze
  ALLOWED_CONTENT_TYPES = %w[application/pdf image/png].freeze

  belongs_to :trabajador, foreign_key: :id_trabajador, inverse_of: :documento

  FILE_FIELDS.each { |field| has_one_attached field }

  validates :id_trabajador, uniqueness: true
  validate :attached_files_are_pdf_or_png

  private

  def attached_files_are_pdf_or_png
    FILE_FIELDS.each do |field|
      attachment = public_send(field)
      next unless attachment.attached?
      next if ALLOWED_CONTENT_TYPES.include?(attachment.blob.content_type)

      errors.add(field, "debe ser PDF o PNG")
    end
  end
end
