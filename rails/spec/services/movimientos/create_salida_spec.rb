require "rails_helper"

RSpec.describe Movimientos::CreateSalida do
  let(:proyecto) { create(:proyecto) }

  it "decrements stock for non-cable salida" do
    articulo = create(:articulo, cantidad_en_stock: 10)
    result = described_class.call(
      proyecto: proyecto,
      responsable: "Ana",
      items: [ { id_articulo: articulo.id_articulo, cantidad: 3 } ]
    )
    expect(result.success?).to eq(true)
    expect(articulo.reload.cantidad_en_stock).to eq(7)
  end

  it "fails when stock is insufficient" do
    articulo = create(:articulo, cantidad_en_stock: 2)
    result = described_class.call(
      proyecto: proyecto,
      responsable: "Ana",
      items: [ { id_articulo: articulo.id_articulo, cantidad: 5 } ]
    )
    expect(result.success?).to eq(false)
    expect(articulo.reload.cantidad_en_stock).to eq(2)
  end

  it "marks cable punta unavailable and decrements by longitud" do
    articulo = create(:articulo, :cable, cantidad_en_stock: 40)
    punta = create(:stock_punta, articulo: articulo, longitud: 15)
    result = described_class.call(
      proyecto: proyecto,
      responsable: "Ana",
      items: [ { id_articulo: articulo.id_articulo, id_punta: punta.id_punta } ]
    )
    expect(result.success?).to eq(true)
    expect(articulo.reload.cantidad_en_stock).to eq(25)
    expect(StockPunta.available).not_to include(punta)
    expect(StockPunta.exists?(punta.id_punta)).to eq(true)
  end
end
