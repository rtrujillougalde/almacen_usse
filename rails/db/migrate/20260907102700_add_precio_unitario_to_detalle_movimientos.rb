# frozen_string_literal: true

class AddPrecioUnitarioToDetalleMovimientos < ActiveRecord::Migration[8.1]
  def change
    add_column :detalle_movimientos, :precio_unitario, :decimal, precision: 12, scale: 2
  end
end
