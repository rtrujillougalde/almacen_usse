module Movimientos
  # Cart items for salidas. Unlike the stock-increase types a salida can only
  # take articulos that already exist, and it is bounded by what is in stock:
  # a cable by a specific punta, anything else by a quantity.
  class SalidaItemBuilder < CartItemBuilder
    def call
      id = params[:id_articulo]
      return error("Debe seleccionar un item") if id.blank?

      articulo = Articulo.find_by(id_articulo: id)
      return error("Artículo no encontrado") unless articulo

      articulo.es_cable? ? build_cable(articulo) : build_material(articulo)
    end

    private

    def build_cable(articulo)
      id_punta = params[:id_punta].presence
      return error("Debe seleccionar una punta/carrete/tramo") if id_punta.blank?

      punta = StockPunta.find_by(id_punta: id_punta)
      return error("Punta no encontrada") unless punta
      return error("Punta no pertenece al artículo") unless punta.id_articulo == articulo.id_articulo
      return error("Punta ya utilizada en una salida") unless StockPunta.available.exists?(id_punta: punta.id_punta)
      return error("Esa punta ya está en la salida actual") if already_in_cart?(punta)

      item(
        "nombre_item" => articulo.nombre,
        "id_articulo" => articulo.id_articulo,
        "es_cable" => true,
        "cantidad" => 0,
        "id_punta" => punta.id_punta,
        "nombre_punta" => punta.nombre_punta,
        "longitud" => punta.longitud.to_f
      )
    end

    def build_material(articulo)
      cantidad = params[:cantidad].to_f
      stock = articulo.cantidad_en_stock.to_f

      errors = [
        ("La cantidad debe ser mayor a 0" if cantidad <= 0),
        ("No hay suficiente stock (disponible: #{stock})" if cantidad > stock)
      ]
      return error(errors) if errors.compact.any?

      item(
        "nombre_item" => articulo.nombre,
        "id_articulo" => articulo.id_articulo,
        "es_cable" => false,
        "cantidad" => cantidad,
        "id_punta" => nil
      )
    end

    # StockPunta.available only knows about puntas consumed by a saved salida,
    # so the cart has to guard against the same punta being added twice before
    # it is confirmed.
    def already_in_cart?(punta)
      cart_items.any? { |i| i["id_punta"].to_s == punta.id_punta.to_s }
    end
  end
end
