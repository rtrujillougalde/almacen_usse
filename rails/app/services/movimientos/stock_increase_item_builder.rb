module Movimientos
  # Cart items for the two movement types that add stock. Entradas use this
  # directly; compras subclass it to require a price first.
  #
  # Either type can name an articulo that does not exist yet, which is what
  # the "__new__" selection means.
  class StockIncreaseItemBuilder < CartItemBuilder
    NEW_SELECTION = "__new__".freeze

    def call
      precio_error = precio_validation_error
      return error(precio_error) if precio_error

      selection = params[:id_articulo].to_s
      return error("Debe seleccionar un item") if selection.blank?

      selection == NEW_SELECTION ? build_new : build_existing(selection)
    end

    private

    # Entradas record no money, so they accept whatever price is sent.
    def precio_validation_error
      nil
    end

    def build_new
      nombre = params[:nombre].to_s.strip
      es_cable = boolean(params[:es_cable])

      errors = [ ("Debe ingresar un nombre para el nuevo item" if nombre.blank?) ]
      errors.concat(quantity_errors(es_cable))
      return error(errors) if errors.compact.any?

      item(
        "is_new" => true,
        "nombre_item" => nombre,
        "nombre" => nombre,
        "num_catalogo" => params[:num_catalogo].to_s,
        "tipo" => params[:tipo].presence || "material",
        "precio_unitario" => params[:precio_unitario],
        "unidad_medida" => params[:unidad_medida],
        "categoria" => params[:categoria],
        "stock_minimo" => params[:stock_minimo],
        "es_cable" => es_cable,
        "nombre_punta" => params[:nombre_punta].to_s,
        "longitud" => params[:longitud].to_f,
        "cantidad" => params[:cantidad].to_f,
        "color" => es_cable ? params[:color].presence : nil
      )
    end

    def build_existing(id)
      articulo = Articulo.find_by(id_articulo: id)
      return error("Artículo no encontrado") unless articulo

      articulo.es_cable? ? build_existing_cable(articulo) : build_existing_material(articulo)
    end

    def build_existing_cable(articulo)
      errors = cable_errors
      return error(errors) if errors.compact.any?

      item(
        "is_new" => false,
        "id_articulo" => articulo.id_articulo,
        "nombre_item" => articulo.nombre,
        "es_cable" => true,
        "nombre_punta" => params[:nombre_punta].to_s,
        "longitud" => params[:longitud].to_f,
        "cantidad" => 0,
        "color" => params[:color].presence,
        "precio_unitario" => params[:precio_unitario]
      )
    end

    def build_existing_material(articulo)
      return error("La cantidad debe ser mayor a 0") if params[:cantidad].to_f <= 0

      item(
        "is_new" => false,
        "id_articulo" => articulo.id_articulo,
        "nombre_item" => articulo.nombre,
        "es_cable" => false,
        "cantidad" => params[:cantidad].to_f,
        "nombre_punta" => "",
        "longitud" => 0,
        "color" => nil,
        "precio_unitario" => params[:precio_unitario]
      )
    end

    # A cable is measured by the length of the punta being added, everything
    # else by a plain quantity.
    def quantity_errors(es_cable)
      return cable_errors if es_cable

      [ ("La cantidad debe ser mayor a 0" if params[:cantidad].to_f <= 0) ]
    end

    def cable_errors
      [
        ("Debe ingresar el nombre de la punta/carrete/tramo" if params[:nombre_punta].to_s.strip.blank?),
        ("La longitud del cable debe ser mayor a 0" if params[:longitud].to_f <= 0)
      ]
    end
  end
end
