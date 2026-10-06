# frozen_string_literal: true

class AddEntregaToProveedores < ActiveRecord::Migration[8.1]
  def change
    add_column :proveedores, :entrega_estado, :string, null: false, default: "desconocida"
    add_column :proveedores, :entrega_monto_minimo, :decimal, precision: 12, scale: 2
    add_column :proveedores, :entrega_moneda, :string, limit: 3
  end
end
