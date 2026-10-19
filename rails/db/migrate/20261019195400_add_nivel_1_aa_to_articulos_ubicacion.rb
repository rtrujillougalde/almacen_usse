# frozen_string_literal: true

class AddNivel1AaToArticulosUbicacion < ActiveRecord::Migration[8.1]
  def up
    # Appended so MySQL can extend the enum without rewriting the table.
    change_column :articulos, :ubicacion,
      "enum('nivel_1','nivel_2','planta_baja','estante_compras','nivel_1_AA')"
  end

  def down
    change_column :articulos, :ubicacion,
      "enum('nivel_1','nivel_2','planta_baja','estante_compras')"
  end
end
