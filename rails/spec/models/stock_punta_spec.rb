require "rails_helper"

RSpec.describe StockPunta, type: :model do
  describe ".available" do
    it "excludes puntas used on a salida detalle" do
      articulo = create(:articulo, :cable, cantidad_en_stock: 50)
      available = create(:stock_punta, articulo: articulo, longitud: 20)
      used = create(:stock_punta, articulo: articulo, longitud: 30)
      proyecto = create(:proyecto)
      salida = create(:movimiento, :salida, proyecto: proyecto)
      create(:detalle_movimiento, movimiento: salida, articulo: articulo, stock_punta: used, cantidad: 30)

      expect(StockPunta.available).to include(available)
      expect(StockPunta.available).not_to include(used)
    end
  end
end
