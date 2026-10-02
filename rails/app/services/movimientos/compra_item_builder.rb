module Movimientos
  class CompraItemBuilder < StockIncreaseItemBuilder
    private

    # A compra is the only movement that records what was paid, so the price
    # is checked before anything else about the item.
    def precio_validation_error
      return if params[:precio_unitario].present? && params[:precio_unitario].to_f.positive?

      "Precio unitario es obligatorio"
    end
  end
end
