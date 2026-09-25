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

  describe "#precio_unitario" do
    it "is an exact two-decimal value rather than a float" do
      articulo = create(:articulo, precio_unitario: "1250.55").reload

      expect(articulo.precio_unitario).to be_a(BigDecimal)
      expect(articulo.precio_unitario).to eq(BigDecimal("1250.55"))
    end
  end

  describe "stock derivation" do
    it "is not derivable for a non-cable" do
      articulo = create(:articulo, cantidad_en_stock: 8)

      expect(articulo.derivable_stock?).to eq(false)
      expect(articulo.stock_drift).to be_nil
      expect(articulo.recalculate_stock!).to eq(false)
      expect(articulo.reload.cantidad_en_stock).to eq(8)
    end

    # The 2,524 rows imported from the old system are in this state: a stock
    # figure with no puntas behind it. Deriving would zero them.
    it "is not derivable for a cable that has no puntas" do
      cable = create(:articulo, :cable, cantidad_en_stock: 120)

      expect(cable.derivable_stock?).to eq(false)
      expect(cable.recalculate_stock!).to eq(false)
      expect(cable.reload.cantidad_en_stock).to eq(120)
    end

    it "sums the puntas still on the shelf" do
      cable = create(:articulo, :cable, cantidad_en_stock: 0)
      create(:stock_punta, articulo: cable, longitud: 25.5)
      create(:stock_punta, articulo: cable, longitud: 10)

      expect(cable.derived_stock).to eq(35.5)
      expect(cable.stock_drift).to eq(35.5)

      expect(cable.recalculate_stock!).to eq(true)
      expect(cable.reload.cantidad_en_stock).to eq(35.5)
      expect(cable.stock_drift).to be_zero
    end

    it "ignores puntas already consumed by a salida" do
      cable = create(:articulo, :cable, cantidad_en_stock: 35.5)
      create(:stock_punta, articulo: cable, longitud: 25.5)
      usada = create(:stock_punta, articulo: cable, longitud: 10)
      salida = create(:movimiento, :salida)
      create(:detalle_movimiento, movimiento: salida, articulo: cable, stock_punta: usada, cantidad: 10)

      expect(cable.derived_stock).to eq(25.5)
      expect(cable.stock_drift).to eq(-10)
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
