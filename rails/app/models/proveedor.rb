class Proveedor < ApplicationRecord
  self.table_name = "proveedores"
  self.primary_key = "id_proveedor"
  self.record_timestamps = false

  has_many :articulos, foreign_key: :proveedor, inverse_of: :proveedor, dependent: :restrict_with_exception

  validates :nombre, presence: true

  before_create :assign_id_proveedor

  private

  def assign_id_proveedor
    self.id_proveedor ||= (self.class.maximum(:id_proveedor) || 0) + 1
  end
end
