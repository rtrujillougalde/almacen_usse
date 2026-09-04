require "test_helper"

class ArticuloTest < ActiveSupport::TestCase
  test "low_stock? compares cantidad against minimo" do
    articulo = Articulo.new(nombre: "Cable", tipo: :material, cantidad_en_stock: 2, stock_minimo: 5)
    assert articulo.low_stock?

    articulo.cantidad_en_stock = 10
    assert_not articulo.low_stock?
  end
end
