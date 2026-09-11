module Movimientos
  class CreateSalida
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
          tipo: :salida,
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
