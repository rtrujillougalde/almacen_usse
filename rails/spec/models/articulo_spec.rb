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

  describe ".nombre_matching" do
    it "matches case insensitively on a substring" do
      cable = create(:articulo, nombre: "Cable Rojo")
      create(:articulo, nombre: "Tornillo")

      expect(described_class.nombre_matching("cable")).to contain_exactly(cable)
    end

    it "returns everything for a blank term" do
      create(:articulo, nombre: "Cable Rojo")
      create(:articulo, nombre: "Tornillo")

      expect(described_class.nombre_matching("").count).to eq(2)
    end

    # % and _ are LIKE wildcards. Unescaped, "50%" matched every articulo
    # starting with 50 and "a_b" matched "axb".
    it "treats % as a literal character" do
      descuento = create(:articulo, nombre: "Cinta 50% algodon")
      create(:articulo, nombre: "Cinta 500 metros")

      expect(described_class.nombre_matching("50%")).to contain_exactly(descuento)
    end

    it "treats _ as a literal character" do
      guion = create(:articulo, nombre: "Cable A_B")
      create(:articulo, nombre: "Cable AXB")

      expect(described_class.nombre_matching("a_b")).to contain_exactly(guion)
    end
  end

  describe ".with_categoria and .with_tipo" do
    it "does not filter on the everything option or a blank value" do
      create(:articulo, categoria: "cables", tipo: :material)
      create(:articulo, categoria: "general", tipo: :herramienta)

      expect(described_class.with_categoria(Articulo::ALL_CATEGORIAS).count).to eq(2)
      expect(described_class.with_tipo(Articulo::ALL_TIPOS).count).to eq(2)
      expect(described_class.with_categoria(nil).with_tipo("").count).to eq(2)
    end

    it "filters on a concrete value" do
      cable = create(:articulo, categoria: "cables", tipo: :material)
      create(:articulo, categoria: "general", tipo: :herramienta)

      expect(described_class.with_categoria("cables")).to contain_exactly(cable)
      expect(described_class.with_tipo("material")).to contain_exactly(cable)
    end
  end
end
