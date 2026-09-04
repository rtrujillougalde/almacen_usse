require "rails_helper"

RSpec.describe Reportes::Query do
  let(:proyecto) { create(:proyecto, c_c: 3210) }

  def add_movement(tipo:, articulo:, cantidad:)
    mov = create(:movimiento, tipo: tipo, proyecto: proyecto)
    create(:detalle_movimiento, movimiento: mov, articulo: articulo, cantidad: cantidad)
  end

  describe ".comparativo_rows" do
    it "computes usado and material cost as precio * usado" do
      articulo = create(:articulo, nombre: "Cemento", tipo: :material, precio_unitario: 10)
      add_movement(tipo: :entrada, articulo: articulo, cantidad: 5)
      add_movement(tipo: :salida, articulo: articulo, cantidad: 8)

      row = described_class.comparativo_rows(cc: 3210).find { |r| r[:material] == "Cemento" }
      expect(row[:usado]).to eq(3)
      expect(row[:costo_material_usado]).to eq(30)
    end

    it "computes herramienta cost as salida * precio * 0.05" do
      articulo = create(:articulo, :herramienta, nombre: "Taladro", precio_unitario: 100)
      add_movement(tipo: :entrada, articulo: articulo, cantidad: 1)
      add_movement(tipo: :salida, articulo: articulo, cantidad: 2)

      row = described_class.comparativo_rows(cc: 3210).find { |r| r[:material] == "Taladro" }
      expect(row[:total_salida]).to eq(2)
      expect(row[:costo_material_usado]).to eq(10.0)
    end
  end

  describe ".movement_rows" do
    it "returns entrada rows for a cost center" do
      articulo = create(:articulo, nombre: "Pintura")
      add_movement(tipo: :entrada, articulo: articulo, cantidad: 4)
      rows = described_class.movement_rows(cc: 3210, movement_type: "entrada")
      expect(rows.map(&:material)).to include("Pintura")
    end
  end
end
