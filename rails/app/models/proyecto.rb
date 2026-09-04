class Proyecto < ApplicationRecord
  self.table_name = "proyectos"
  self.primary_key = "id_proyecto"
  self.record_timestamps = false

  has_many :movimientos, foreign_key: :id_proyecto, inverse_of: :proyecto, dependent: :restrict_with_exception

  validates :c_c, presence: true, uniqueness: true
  validates :nombre_obra, presence: true

  def nombre_obra_with_cc
    "#{c_c} | #{nombre_obra}"
  end
end
