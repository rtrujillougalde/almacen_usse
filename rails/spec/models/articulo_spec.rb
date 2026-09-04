require "rails_helper"

RSpec.describe Articulo, type: :model do
  describe "#low_stock?" do
    it "is true when stock is below minimo" do
      articulo = build(:articulo, cantidad_en_stock: 1, stock_minimo: 5)
      expect(articulo).to be_low_stock
    end

    it "is false when stock meets minimo" do
      articulo = build(:articulo, cantidad_en_stock: 10, stock_minimo: 5)
      expect(articulo).not_to be_low_stock
    end
  end
end
