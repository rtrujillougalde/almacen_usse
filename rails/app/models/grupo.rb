class Grupo < ApplicationRecord
  self.record_timestamps = false

  has_many :trabajadores,
           class_name: "Trabajador",
           foreign_key: :grupo_id,
           inverse_of: :grupo,
           dependent: :restrict_with_exception

  validates :nombre, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 50 }
end
