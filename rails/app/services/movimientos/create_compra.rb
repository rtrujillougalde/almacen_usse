module Movimientos
  class CreateCompra < StockIncrease
    def initialize(proyecto:, moneda:, proveedor:, items:, responsable:, observaciones: nil)
      super(proyecto: proyecto, responsable: responsable, items: items, observaciones: observaciones)
      @moneda = moneda
      @proveedor = proveedor
    end

    private

    def tipo
      :compra
    end

    def precio_required?
      true
    end

    def extra_validation_error
      return "Moneda es obligatoria" if @moneda.blank?
      return "Moneda inválida" unless Movimiento::MONEDAS.include?(@moneda.to_s)
      return "Proveedor es obligatorio" if @proveedor.blank?

      nil
    end

    def movimiento_attributes
      super.merge(moneda: @moneda, proveedor: @proveedor)
    end
  end
end
