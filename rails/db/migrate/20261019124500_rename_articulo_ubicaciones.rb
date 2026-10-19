# frozen_string_literal: true

class RenameArticuloUbicaciones < ActiveRecord::Migration[8.1]
  def up
    change_to_string
    rename_values(
      "nivel_1" => "nivel 1",
      "nivel_2" => "nivel 2",
      "planta_baja" => "planta baja",
      "estante_compras" => "estante compras"
    )
    change_to_enum([
      "nivel 1",
      "nivel 1-aire acondicionado",
      "nivel 2",
      "planta baja",
      "estante compras"
    ])
  end

  def down
    change_to_string
    execute "UPDATE articulos SET ubicacion = NULL WHERE ubicacion = 'nivel 1-aire acondicionado'"
    rename_values(
      "nivel 1" => "nivel_1",
      "nivel 2" => "nivel_2",
      "planta baja" => "planta_baja",
      "estante compras" => "estante_compras"
    )
    change_to_enum(%w[nivel_1 nivel_2 planta_baja estante_compras])
  end

  private

  def change_to_string
    change_column :articulos, :ubicacion, :string, limit: 50
  end

  def rename_values(mapping)
    mapping.each do |from, to|
      execute "UPDATE articulos SET ubicacion = #{connection.quote(to)} WHERE ubicacion = #{connection.quote(from)}"
    end
  end

  def change_to_enum(values)
    quoted = values.map { |value| connection.quote(value) }.join(",")
    execute "ALTER TABLE articulos MODIFY ubicacion ENUM(#{quoted})"
  end
end
