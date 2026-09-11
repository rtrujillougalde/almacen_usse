module Movimientos
  class CreateSalida < Base
    private

    def tipo
      :salida
    end

    # The only movement type that locks. A salida reads stock and punta
    # availability to decide whether it may proceed, so two concurrent salidas
    # could otherwise both pass the check and oversell the same articulo.
    def process_item!(movimiento, item)
      articulo = Articulo.lock.find(item[:id_articulo])

      if articulo.es_cable?
        punta = StockPunta.lock.find(item[:id_punta])
        raise ArgumentError, "Punta no pertenece al artículo" unless punta.id_articulo == articulo.id_articulo
        unless StockPunta.available.exists?(id_punta: punta.id_punta)
          raise ArgumentError, "Punta ya utilizada en una salida"
        end
        qty = punta.longitud.to_f
        raise ArgumentError, "Stock insuficiente para punta" if articulo.cantidad_en_stock.to_f < qty

        articulo.update!(cantidad_en_stock: articulo.cantidad_en_stock.to_f - qty)
        DetalleMovimiento.create!(movimiento: movimiento, articulo: articulo, stock_punta: punta, cantidad: qty)
      else
        qty = item[:cantidad].to_f
        raise ArgumentError, "Cantidad inválida" if qty <= 0
        raise ArgumentError, "Stock insuficiente para #{articulo.nombre}" if articulo.cantidad_en_stock.to_f < qty

        articulo.update!(cantidad_en_stock: articulo.cantidad_en_stock.to_f - qty)
        DetalleMovimiento.create!(movimiento: movimiento, articulo: articulo, cantidad: qty)
      end
    end
  end
end
