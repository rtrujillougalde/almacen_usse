require "test_helper"

class ProyectoTest < ActiveSupport::TestCase
  test "c_c must be unique" do
    Proyecto.create!(c_c: 1001, nombre_obra: "Obra A", encargado: "Ana")
    dup = Proyecto.new(c_c: 1001, nombre_obra: "Obra B", encargado: "Luis")
    assert_not dup.valid?
    assert_includes dup.errors[:c_c], "has already been taken"
  end
end
