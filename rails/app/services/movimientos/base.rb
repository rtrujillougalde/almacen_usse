module Movimientos
  # Every movement is the same transaction: validate the header, create one
  # Movimiento, then process each cart item inside it. Subclasses supply the
  # tipo and decide what processing an item means.
  #
  # The header guards duplicate the controllers on purpose. They are a safety
  # net for non-UI callers, not the messages users are meant to see.
  class Base
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
      error = validation_error
      return failure(error) if error

      movimiento = nil
      ActiveRecord::Base.transaction do
        movimiento = Movimiento.create!(movimiento_attributes)
        @items.each { |item| process_item!(movimiento, item) }
      end

      Result.new(success?: true, movimiento: movimiento)
    rescue ActiveRecord::RecordInvalid, ArgumentError => e
      Result.new(success?: false, error: e.message)
    end

    private

    def validation_error
      return "Responsable es obligatorio" if @responsable.blank?
      return "Proyecto es obligatorio" if @proyecto.blank?

      extra = extra_validation_error
      return extra if extra

      return "Agrega al menos un artículo" if @items.blank?

      nil
    end

    # Checked between the proyecto and the items, so subclasses can add header
    # requirements without disturbing the order of the shared ones.
    def extra_validation_error
      nil
    end

    def movimiento_attributes
      {
        proyecto: @proyecto,
        tipo: tipo,
        responsable: @responsable,
        observaciones: @observaciones,
        fecha_hora: Time.current
      }
    end

    def tipo
      raise NotImplementedError
    end

    def process_item!(_movimiento, _item)
      raise NotImplementedError
    end

    def failure(message)
      Result.new(success?: false, error: message)
    end
  end
end
