module Movimientos
  class CreateEntrada < StockIncrease
    private

    def tipo
      :entrada
    end
  end
end
