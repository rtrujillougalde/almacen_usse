module Reportes
  class Query
    def self.movement_rows(cc:, movement_type:, date_from: nil, date_to: nil)
      scope = DetalleMovimiento
        .joins(movimiento: :proyecto, articulo: [])
        .where(proyectos: { c_c: cc })
        .where(movimientos: { tipo: movement_type })
        .select(
          "movimientos.fecha_hora",
          "proyectos.c_c",
          "articulos.nombre AS material",
          "detalle_movimientos.cantidad",
          "articulos.precio_unitario",
          "articulos.unidad_medida"
        )
        .order("movimientos.fecha_hora")

      scope = scope.where("DATE(movimientos.fecha_hora) >= ?", date_from) if date_from.present?
      scope = scope.where("DATE(movimientos.fecha_hora) <= ?", date_to) if date_to.present?
      scope
    end

    def self.comparativo_rows(cc:, date_from: nil, date_to: nil)
      entradas = movement_totals(cc, "entrada", date_from, date_to)
      salidas = movement_totals(cc, "salida", date_from, date_to)
      names = (entradas.keys + salidas.keys).uniq

      names.map do |nombre|
        art = Articulo.find_by(nombre: nombre)
        total_e = entradas[nombre].to_f
        total_s = salidas[nombre].to_f
        usado = total_s - total_e
        precio = art&.precio_unitario.to_f
        tipo = art&.tipo || "material"
        costo = if tipo == "herramienta"
          total_s * precio * 0.05
        else
          precio * usado
        end

        {
          c_c: cc,
          material: nombre,
          tipo: tipo,
          unidad_medida: art&.unidad_medida,
          precio_unitario: precio,
          total_entrada: total_e,
          total_salida: total_s,
          usado: usado,
          costo_material_usado: costo
        }
      end
    end

    def self.movement_totals(cc, tipo, date_from, date_to)
      rows = movement_rows(cc: cc, movement_type: tipo, date_from: date_from, date_to: date_to)
      rows.each_with_object(Hash.new(0.0)) do |row, hash|
        hash[row.material] += row.cantidad.to_f
      end
    end
  end
end
