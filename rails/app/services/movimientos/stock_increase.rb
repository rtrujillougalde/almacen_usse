module Movimientos
  # Compras and entradas both add stock, either by creating an articulo or by
  # topping up an existing one. They differ only in whether a unit price is
  # required and recorded, which is what precio_required? selects.
  class StockIncrease < Base
    private

    def precio_required?
      false
    end

    def process_item!(movimiento, item)
      if item[:is_new]
        create_new_item!(movimiento, item)
      else
        update_existing_item!(movimiento, item)
      end
    end

    def create_new_item!(movimiento, item)
      raise ArgumentError, "Nombre de artículo requerido" if item[:nombre].blank?

      precio = resolve_precio!(item, item[:nombre])
      es_cable = ActiveModel::Type::Boolean.new.cast(item[:es_cable])
      cantidad = es_cable ? item[:longitud].to_f : item[:cantidad].to_f
      raise ArgumentError, "Cantidad/longitud inválida para #{item[:nombre]}" if cantidad <= 0
      raise ArgumentError, "Punta requerida para cable nuevo" if es_cable && item[:nombre_punta].blank?

      articulo = Articulo.create!(
        nombre: item[:nombre],
        num_catalogo: item[:num_catalogo],
        tipo: item[:tipo].presence || "material",
        precio_unitario: precio,
        unidad_medida: item[:unidad_medida],
        categoria: item[:categoria],
        stock_minimo: item[:stock_minimo],
        es_cable: es_cable,
        cantidad_en_stock: cantidad
      )

      punta = create_punta!(articulo, item) if es_cable
      create_detalle!(movimiento, articulo, punta, cantidad, precio)
    end

    def update_existing_item!(movimiento, item)
      articulo = Articulo.find(item[:id_articulo])
      precio = resolve_precio!(item, articulo.nombre)

      if articulo.es_cable?
        raise ArgumentError, "Nombre de punta requerido" if item[:nombre_punta].blank?
        longitud = item[:longitud].to_f
        raise ArgumentError, "Longitud inválida" if longitud <= 0

        punta = create_punta!(articulo, item, longitud)
        increase_stock!(articulo, longitud, precio)
        create_detalle!(movimiento, articulo, punta, longitud, precio)
      else
        cantidad = item[:cantidad].to_f
        raise ArgumentError, "Cantidad inválida" if cantidad <= 0

        increase_stock!(articulo, cantidad, precio)
        create_detalle!(movimiento, articulo, nil, cantidad, precio)
      end
    end

    # Passed straight through when the movement type does not record prices, so
    # an entrada still stores whatever the caller sent without validating it.
    def resolve_precio!(item, nombre)
      return item[:precio_unitario] unless precio_required?

      raise ArgumentError, "Precio unitario es obligatorio" if item[:precio_unitario].blank?

      precio = item[:precio_unitario].to_f
      raise ArgumentError, "Precio unitario inválido para #{nombre}" if precio <= 0

      precio
    end

    def create_punta!(articulo, item, longitud = item[:longitud])
      StockPunta.create!(
        articulo: articulo,
        nombre_punta: item[:nombre_punta],
        longitud: longitud,
        color: item[:color]
      )
    end

    def increase_stock!(articulo, cantidad, precio)
      attributes = { cantidad_en_stock: articulo.cantidad_en_stock.to_f + cantidad }
      attributes[:precio_unitario] = precio if precio_required?
      articulo.update!(**attributes)
    end

    def create_detalle!(movimiento, articulo, punta, cantidad, precio)
      attributes = {
        movimiento: movimiento,
        articulo: articulo,
        stock_punta: punta,
        cantidad: cantidad
      }
      attributes[:precio_unitario] = precio if precio_required?
      DetalleMovimiento.create!(**attributes)
    end
  end
end
