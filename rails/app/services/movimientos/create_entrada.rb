module Movimientos
  class CreateEntrada
    Result = Struct.new(:success?, :movimiento, :error, keyword_init: true)

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(proyecto:, responsable:, items:, observaciones: nil)
      @proyecto = proyecto
      @responsable = responsable
      @items = items
      @observaciones = observaciones
    end

    def call
      return failure("Responsable es obligatorio") if @responsable.blank?
      return failure("Proyecto es obligatorio") if @proyecto.blank?
      return failure("Agrega al menos un artículo") if @items.blank?

      movimiento = nil
      ActiveRecord::Base.transaction do
        movimiento = Movimiento.create!(
          proyecto: @proyecto,
          tipo: :entrada,
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

    def create_new_item!(movimiento, item)
      raise ArgumentError, "Nombre de artículo requerido" if item[:nombre].blank?

      es_cable = ActiveModel::Type::Boolean.new.cast(item[:es_cable])
      cantidad = es_cable ? item[:longitud].to_f : item[:cantidad].to_f
      raise ArgumentError, "Cantidad/longitud inválida para #{item[:nombre]}" if cantidad <= 0
      raise ArgumentError, "Punta requerida para cable nuevo" if es_cable && item[:nombre_punta].blank?

      articulo = Articulo.create!(
        nombre: item[:nombre],
        num_catalogo: item[:num_catalogo],
        tipo: item[:tipo].presence || "material",
        precio_unitario: item[:precio_unitario],
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
        cantidad: cantidad
      )
    end

    def update_existing_item!(movimiento, item)
      articulo = Articulo.find(item[:id_articulo])
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
        articulo.update!(cantidad_en_stock: articulo.cantidad_en_stock.to_f + longitud)
        DetalleMovimiento.create!(movimiento: movimiento, articulo: articulo, stock_punta: punta, cantidad: longitud)
      else
        cantidad = item[:cantidad].to_f
        raise ArgumentError, "Cantidad inválida" if cantidad <= 0
        articulo.update!(cantidad_en_stock: articulo.cantidad_en_stock.to_f + cantidad)
        DetalleMovimiento.create!(movimiento: movimiento, articulo: articulo, cantidad: cantidad)
      end
    end
  end
end
