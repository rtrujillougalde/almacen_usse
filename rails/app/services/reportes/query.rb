module Reportes
  class Query
    def self.movement_rows(cc:, movement_type:, date_from: nil, date_to: nil)
      scope = DetalleMovimiento
        .joins(movimiento: :proyecto)
        .joins(:articulo)
        .left_joins(movimiento: :proveedor)
        .where(proyectos: { c_c: cc })
        .where(movimientos: { tipo: movement_type })
        .select(
          "movimientos.fecha_hora",
          "proyectos.c_c",
          "articulos.nombre AS material",
          "detalle_movimientos.cantidad",
          "detalle_movimientos.precio_unitario",
          "articulos.unidad_medida",
          "movimientos.moneda",
          "proveedores.nombre AS proveedor"
        )
        .order("movimientos.fecha_hora DESC")

      apply_date_window(scope, date_from, date_to)
    end

    def self.utilizado_groups(cc:, date_from: nil, date_to: nil)
      lookup = latest_compra_monedas(cc)
      Movimiento::MONEDAS.filter_map do |moneda|
        rows = utilizado_rows_for(
          cc: cc, moneda: moneda, date_from: date_from, date_to: date_to, lookup: lookup
        )
        next if rows.empty?

        {
          moneda: moneda,
          rows: rows,
          total_costo: rows.sum { |r| r[:costo].to_f }
        }
      end
    end

    def self.movement_totals(cc, tipo, date_from, date_to, moneda: nil, lookup: {})
      rows = movement_rows(cc: cc, movement_type: tipo, date_from: date_from, date_to: date_to)
      rows = rows.select { |row| resolved_moneda(row, tipo, lookup) == moneda } if moneda
      rows.each_with_object(Hash.new(0.0)) do |row, hash|
        hash[row.material] += row.cantidad.to_f
      end
    end

    def self.utilizado_rows_for(cc:, moneda:, date_from:, date_to:, lookup:)
      compras = movement_totals(cc, "compra", date_from, date_to, moneda: moneda, lookup: lookup)
      salidas = movement_totals(cc, "salida", date_from, date_to, moneda: moneda, lookup: lookup)
      entradas = movement_totals(cc, "entrada", date_from, date_to, moneda: moneda, lookup: lookup)
      names = (compras.keys + salidas.keys + entradas.keys).uniq.sort
      articles = Articulo.where(nombre: names).index_by(&:nombre)

      names.map do |nombre|
        art = articles[nombre]
        total_c = compras[nombre].to_f
        total_s = salidas[nombre].to_f
        total_e = entradas[nombre].to_f
        precio = art&.precio_unitario.to_f
        tipo = art&.tipo || "material"
        utilizado = if tipo == "herramienta"
          total_c + total_s
        else
          total_c + total_s - total_e
        end
        costo = if tipo == "herramienta"
          precio * utilizado * 0.05
        else
          precio * utilizado
        end

        {
          c_c: cc,
          moneda: moneda,
          material: nombre,
          tipo: tipo,
          unidad_medida: art&.unidad_medida || "N/A",
          precio_unitario: precio,
          total_compra: total_c,
          total_salida: total_s,
          total_entrada: total_e,
          utilizado: utilizado,
          costo: costo
        }
      end.sort_by { |r| [ r[:c_c].to_s, r[:material].to_s ] }
    end
    private_class_method :utilizado_rows_for

    def self.latest_compra_monedas(cc)
      DetalleMovimiento
        .joins(movimiento: :proyecto)
        .joins(:articulo)
        .where(proyectos: { c_c: cc }, movimientos: { tipo: "compra" })
        .where(movimientos: { moneda: Movimiento::MONEDAS })
        .order("movimientos.fecha_hora DESC", "movimientos.id_movimiento DESC")
        .pluck("articulos.nombre", "movimientos.moneda")
        .each_with_object({}) { |(nombre, moneda), hash| hash[nombre] ||= moneda }
    end
    private_class_method :latest_compra_monedas

    def self.resolved_moneda(row, tipo, lookup)
      return row.moneda if tipo == "compra" && row.moneda.present?

      lookup[row.material].presence || "MXN"
    end
    private_class_method :resolved_moneda

    def self.apply_date_window(scope, date_from, date_to)
      return scope unless date_from.present? && date_to.present?

      from = Time.zone.parse(date_from.to_s).beginning_of_day
      to = Time.zone.parse(date_to.to_s).end_of_day
      scope.where(movimientos: { fecha_hora: from..to })
    end
    private_class_method :apply_date_window
  end
end
