class ChangeArticulosPrecioUnitarioToDecimal < ActiveRecord::Migration[8.1]
  # Money in a float rounds badly and compares badly. detalle_movimientos
  # already stores precio_unitario as decimal(12,2); this brings the articulo
  # column in line so a price does not change shape as it moves between them.
  def up
    change_column :articulos, :precio_unitario, :decimal, precision: 12, scale: 2
  end

  def down
    change_column :articulos, :precio_unitario, :float
  end
end
