ActiveSupport::Inflector.inflections(:en) do |inflect|
  # Explicit rules first — "proveedores".singularize would otherwise become "proveedore".
  inflect.singular(/proveedores$/i, "proveedor")
  inflect.plural(/proveedor$/i, "proveedores")
  inflect.singular(/trabajadores$/i, "trabajador")
  inflect.plural(/trabajador$/i, "trabajadores")
  inflect.irregular "proveedor", "proveedores"

  inflect.irregular "proyecto", "proyectos"
  inflect.irregular "articulo", "articulos"
  inflect.irregular "movimiento", "movimientos"
  inflect.irregular "detalle_movimiento", "detalle_movimientos"
  inflect.irregular "stock_punta", "stock_puntas"
  inflect.irregular "entrada", "entradas"
  inflect.irregular "compra", "compras"
  inflect.irregular "salida", "salidas"
  inflect.irregular "reporte", "reportes"
  inflect.irregular "usuario", "usuarios"
  inflect.irregular "trabajador", "trabajadores"
  inflect.irregular "documento", "documentos"
  inflect.irregular "epp_movimiento", "epp_movimientos"
end
