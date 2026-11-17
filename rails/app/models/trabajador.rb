class Trabajador < ApplicationRecord
  self.table_name = "trabajadores_datos"
  self.record_timestamps = false

  belongs_to :grupo
  has_one :documento, foreign_key: :id_trabajador, inverse_of: :trabajador, dependent: :destroy
  has_many :epp_movimientos, foreign_key: :id_trabajador, inverse_of: :trabajador, dependent: :restrict_with_exception

  enum :antidoping, { apto: "apto", no_apto: "no_apto" }, validate: { allow_nil: true }
  enum :tipo_sangre, {
    o_positivo: "O+",
    o_negativo: "O-",
    a_positivo: "A+",
    a_negativo: "A-",
    b_positivo: "B+",
    b_negativo: "B-",
    ab_positivo: "AB+",
    ab_negativo: "AB-"
  }, validate: { allow_nil: true }

  validates :nombre, presence: true, length: { maximum: 150 }
  validates :id_usse, uniqueness: true, numericality: { only_integer: true, greater_than_or_equal_to: 400 }
  validates :activo, inclusion: { in: [ true, false ] }

  before_validation :assign_id_usse, on: :create

  private

  def assign_id_usse
    return if id_usse.present?

    current = self.class.maximum(:id_usse)
    self.id_usse = current ? current + 1 : 400
  end
end
