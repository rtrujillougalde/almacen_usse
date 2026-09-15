class Proyecto < ApplicationRecord
  before_validation {self.c_c=c_c.to_s.strip.presence}
  self.table_name = "proyectos"
  self.primary_key = "id_proyecto"
  self.record_timestamps = false

  has_many :movimientos, foreign_key: :id_proyecto, inverse_of: :proyecto, dependent: :restrict_with_exception

  validates :c_c, presence: true, uniqueness: true, length: {maximum: 50}
  validates :nombre_obra, presence: true

  def nombre_obra_with_cc
    "#{c_c} | #{nombre_obra}"
  end
end
