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

  it "fails when the punta belongs to another articulo" do
    articulo = create(:articulo, :cable, cantidad_en_stock: 40)
    ajena = create(:stock_punta, longitud: 15)

    result = described_class.call(
      proyecto: proyecto,
      responsable: "Ana",
      items: [ { id_articulo: articulo.id_articulo, id_punta: ajena.id_punta } ]
    )

    expect(result.success?).to eq(false)
    expect(result.error).to include("Punta no pertenece al artículo")
    expect(articulo.reload.cantidad_en_stock).to eq(40)
  end

  it "fails when the punta was already consumed by another salida" do
    articulo = create(:articulo, :cable, cantidad_en_stock: 40)
    punta = create(:stock_punta, articulo: articulo, longitud: 15)
    previa = create(:movimiento, :salida, proyecto: proyecto)
    create(:detalle_movimiento, movimiento: previa, articulo: articulo, stock_punta: punta, cantidad: 15)

    result = described_class.call(
      proyecto: proyecto,
      responsable: "Ana",
      items: [ { id_articulo: articulo.id_articulo, id_punta: punta.id_punta } ]
    )

    expect(result.success?).to eq(false)
    expect(result.error).to include("Punta ya utilizada en una salida")
    expect(articulo.reload.cantidad_en_stock).to eq(40)
  end

  it "fails when the cable stock is below the punta longitud" do
    articulo = create(:articulo, :cable, cantidad_en_stock: 5)
    punta = create(:stock_punta, articulo: articulo, longitud: 15)

    result = described_class.call(
      proyecto: proyecto,
      responsable: "Ana",
      items: [ { id_articulo: articulo.id_articulo, id_punta: punta.id_punta } ]
    )

    expect(result.success?).to eq(false)
    expect(result.error).to include("Stock insuficiente para punta")
    expect(articulo.reload.cantidad_en_stock).to eq(5)
    expect(StockPunta.available).to include(punta)
  end
end
