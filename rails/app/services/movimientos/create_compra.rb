module Movimientos
  class CreateCompra
    Result = Struct.new(:success?, :movimiento, :error, keyword_init: true)

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(proyecto:, moneda:, proveedor:, items:, responsable: nil, observaciones: nil)
      @proyecto = proyecto
      @moneda = moneda
      @proveedor = proveedor
      @items = items
      @responsable = responsable
      @observaciones = observaciones
    end

    def call
      return failure("Proyecto es obligatorio") if @proyecto.blank?
      return failure("Moneda es obligatoria") if @moneda.blank?
      return failure("Moneda inválida") unless Movimiento::MONEDAS.include?(@moneda.to_s)
      return failure("Proveedor es obligatorio") if @proveedor.blank?
      return failure("Agrega al menos un artículo") if @items.blank?

      movimiento = nil
      ActiveRecord::Base.transaction do
        movimiento = Movimiento.create!(
          proyecto: @proyecto,
          tipo: :compra,
          moneda: @moneda,
          proveedor: @proveedor,
          responsable: @responsable,
          observaciones: @observaciones,
          fecha_hora: Time.current
        )

        @items.each { |item| process_item!(movimiento, item) }
      end

      Result.new(success?: true, movimiento: movimiento)
    rescue ActiveRecord::RecordInvalid, ArgumentError => e
      Result.new(success?: false, error: e.message)
    end

    private

    def failure(message)
      Result.new(success?: false, error: message)
    end

    def process_item!(movimiento, item)
      if item[:is_new]
        create_new_item!(movimiento, item)
      else
        update_existing_item!(movimiento, item)
      end
    end

    def resolve_precio!(item, nombre)
      raise ArgumentError, "Precio unitario es obligatorio" if item[:precio_unitario].blank?

      precio = item[:precio_unitario].to_f
      raise ArgumentError, "Precio unitario inválido para #{nombre}" if precio <= 0

      precio
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

      punta = nil
      if es_cable
        punta = StockPunta.create!(
          articulo: articulo,
          nombre_punta: item[:nombre_punta],
          longitud: item[:longitud],
          color: item[:color]
        )
      end

      DetalleMovimiento.create!(
        movimiento: movimiento,
        articulo: articulo,
        stock_punta: punta,
        cantidad: cantidad,
        precio_unitario: precio
      )
    end

    def update_existing_item!(movimiento, item)
      articulo = Articulo.find(item[:id_articulo])
      precio = resolve_precio!(item, articulo.nombre)

      if articulo.es_cable?
        raise ArgumentError, "Nombre de punta requerido" if item[:nombre_punta].blank?
        longitud = item[:longitud].to_f
        raise ArgumentError, "Longitud inválida" if longitud <= 0

        punta = StockPunta.create!(
          articulo: articulo,
          nombre_punta: item[:nombre_punta],
          longitud: longitud,
          color: item[:color]
        )
        articulo.update!(cantidad_en_stock: articulo.cantidad_en_stock.to_f + longitud, precio_unitario: precio)
        DetalleMovimiento.create!(
          movimiento: movimiento,
          articulo: articulo,
          stock_punta: punta,
          cantidad: longitud,
          precio_unitario: precio
        )
      else
        cantidad = item[:cantidad].to_f
        raise ArgumentError, "Cantidad inválida" if cantidad <= 0

        articulo.update!(cantidad_en_stock: articulo.cantidad_en_stock.to_f + cantidad, precio_unitario: precio)
        DetalleMovimiento.create!(
          movimiento: movimiento,
          articulo: articulo,
          cantidad: cantidad,
          precio_unitario: precio
        )
      end
    end
  end
end
