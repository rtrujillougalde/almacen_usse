require "rails_helper"

RSpec.describe Movimientos::CreateEntrada do
  let(:proyecto) { create(:proyecto) }

  # An entrada records no money: unlike a compra it never overwrites the
  # articulo price and never stamps one on the detalle, even when the caller
  # supplies one. This is the difference precio_required? selects.
  it "records no price on the detalle and leaves the articulo price alone" do
    articulo = create(:articulo, cantidad_en_stock: 5, precio_unitario: 100)

    result = described_class.call(
      proyecto: proyecto,
      responsable: "Ana",
      items: [ { is_new: false, id_articulo: articulo.id_articulo, cantidad: 3, precio_unitario: 999 } ]
    )

    expect(result.success?).to eq(true)
    expect(articulo.reload.cantidad_en_stock).to eq(8)
    expect(articulo.precio_unitario).to eq(100)
    expect(result.movimiento.detalle_movimientos.sole.precio_unitario).to be_nil
  end

  it "creates new non-cable article and increments stock" do
    result = described_class.call(
      proyecto: proyecto,
      responsable: "Ana",
      items: [ {
        is_new: true,
        nombre: "Tornillo Spec",
        tipo: "material",
        cantidad: 10,
        unidad_medida: "pza",
        categoria: "tornilleria",
        stock_minimo: 2,
        es_cable: false,
        precio_unitario: 1.5
      } ]
    )

    expect(result.success?).to eq(true)
    articulo = Articulo.find_by!(nombre: "Tornillo Spec")
    expect(articulo.cantidad_en_stock).to eq(10)
    expect(result.movimiento.detalle_movimientos.first.cantidad).to eq(10)
  end

  it "creates cable with punta and uses longitud as stock" do
    result = described_class.call(
      proyecto: proyecto,
      responsable: "Ana",
      items: [ {
        is_new: true,
        nombre: "Cable Spec",
        tipo: "material",
        es_cable: true,
        nombre_punta: "Bobina 1",
        longitud: 33,
        color: "rojo",
        unidad_medida: "m",
        categoria: "cables"
      } ]
    )

    expect(result.success?).to eq(true)
    articulo = Articulo.find_by!(nombre: "Cable Spec")
    expect(articulo.es_cable).to eq(true)
    expect(articulo.cantidad_en_stock).to eq(33)
    expect(articulo.stock_puntas.count).to eq(1)
  end

  it "adds stock to existing non-cable article" do
    articulo = create(:articulo, cantidad_en_stock: 5)
    result = described_class.call(
      proyecto: proyecto,
      responsable: "Ana",
      items: [ { is_new: false, id_articulo: articulo.id_articulo, cantidad: 3 } ]
    )
    expect(result.success?).to eq(true)
    expect(articulo.reload.cantidad_en_stock).to eq(8)
  end

  it "fails without responsable" do
    result = described_class.call(proyecto: proyecto, responsable: "", items: [ { is_new: true, nombre: "X", cantidad: 1 } ])
    expect(result.success?).to eq(false)
    expect(result.error).to match(/Responsable/i)
  end

  it "fails with empty items" do
    result = described_class.call(proyecto: proyecto, responsable: "Ana", items: [])
    expect(result.success?).to eq(false)
  end
end
