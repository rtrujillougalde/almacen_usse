# frozen_string_literal: true

class AddCompraFieldsToMovimientos < ActiveRecord::Migration[8.1]
  def up
    change_column :movimientos, :tipo, "enum('entrada','salida','compra')", null: false
    add_column :movimientos, :moneda, :string, limit: 3
    add_column :movimientos, :id_proveedor, :integer
    add_index :movimientos, :id_proveedor
    add_foreign_key :movimientos, :proveedores, column: :id_proveedor, primary_key: :id_proveedor
  end

  def down
    remove_foreign_key :movimientos, column: :id_proveedor
    remove_index :movimientos, :id_proveedor
    remove_column :movimientos, :id_proveedor
    remove_column :movimientos, :moneda
    change_column :movimientos, :tipo, "enum('entrada','salida')", null: false
  end
end
