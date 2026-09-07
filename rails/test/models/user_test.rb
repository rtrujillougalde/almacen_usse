require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "admin can access all warehouse pages" do
    user = users(:admin)
    assert user.can_access?("proveedores")
    assert user.can_access?("entradas")
    assert user.can_access?("compras")
  end

  test "consulta cannot access entradas or proveedores" do
    user = users(:consulta)
    assert user.can_access?("inventario")
    assert user.can_access?("reportes")
    assert_not user.can_access?("entradas")
    assert_not user.can_access?("proveedores")
  end
end
