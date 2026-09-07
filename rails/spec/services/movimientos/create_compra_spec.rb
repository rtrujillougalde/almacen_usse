require "rails_helper"

RSpec.describe Movimientos::CreateCompra do
  let(:proyecto) { create(:proyecto) }
  let(:proveedor) { create(:proveedor) }
  let(:valid_new_item) do
    {
      is_new: true,
      nombre: "Tornillo Compra",
      tipo: "material",
      cantidad: 10,
      unidad_medida: "pza",
      categoria: "tornilleria",
      stock_minimo: 2,
      es_cable: false,
      precio_unitario: 4.5
    }
  end

  def call_service(proyecto: self.proyecto, moneda: "MXN", proveedor: self.proveedor, items: [ valid_new_item ])
    described_class.call(proyecto: proyecto, moneda: moneda, proveedor: proveedor, items: items)
  end

  it "fails without proyecto" do
    expect {
      result = call_service(proyecto: nil)
      expect(result.success?).to eq(false)
      expect(result.error).to eq("Proyecto es obligatorio")
    }.not_to change(Movimiento, :count)
  end

  it "fails without moneda" do
    result = call_service(moneda: nil)
    expect(result.success?).to eq(false)
    expect(result.error).to eq("Moneda es obligatoria")
  end

  it "fails without proveedor" do
    result = call_service(proveedor: nil)
    expect(result.success?).to eq(false)
    expect(result.error).to eq("Proveedor es obligatorio")
  end

  it "fails with invalid moneda" do
    result = call_service(moneda: "EUR")
    expect(result.success?).to eq(false)
    expect(result.error).to eq("Moneda inválida")
  end

  it "fails with empty items" do
    result = call_service(items: [])
    expect(result.success?).to eq(false)
    expect(result.error).to eq("Agrega al menos un artículo")
  end

  it "fails when precio_unitario is missing" do
    result = call_service(items: [ valid_new_item.merge(precio_unitario: nil) ])
    expect(result.success?).to eq(false)
    expect(result.error).to eq("Precio unitario es obligatorio")
  end

  it "fails when precio_unitario is not greater than 0" do
    result = call_service(items: [ valid_new_item.merge(precio_unitario: 0) ])
    expect(result.success?).to eq(false)
    expect(result.error).to match(/Precio unitario inválido/)
  end

  it "creates a compra with moneda, proveedor, stock, and precio on articulo and detalle" do
    result = call_service

    expect(result.success?).to eq(true)
    expect(result.movimiento.compra?).to eq(true)
    expect(result.movimiento.moneda).to eq("MXN")
    expect(result.movimiento.proveedor).to eq(proveedor)

    articulo = Articulo.find_by!(nombre: "Tornillo Compra")
    expect(articulo.cantidad_en_stock).to eq(10)
    expect(articulo.precio_unitario).to eq(4.5)

    detalle = result.movimiento.detalle_movimientos.first
    expect(detalle.cantidad).to eq(10)
    expect(detalle.precio_unitario).to eq(4.5)
  end

  it "adds stock and overwrites precio_unitario on an existing article" do
    articulo = create(:articulo, cantidad_en_stock: 5, precio_unitario: 100)
    result = call_service(items: [ {
      is_new: false,
      id_articulo: articulo.id_articulo,
      cantidad: 3,
      precio_unitario: 12.25
    } ])

    expect(result.success?).to eq(true)
    articulo.reload
    expect(articulo.cantidad_en_stock).to eq(8)
    expect(articulo.precio_unitario).to eq(12.25)
    expect(result.movimiento.detalle_movimientos.first.precio_unitario).to eq(12.25)
  end

  it "creates a cable compra with punta, stock from longitud, and precio on both records" do
    result = call_service(items: [ {
      is_new: true,
      nombre: "Cable Compra",
      tipo: "material",
      es_cable: true,
      nombre_punta: "Bobina 1",
      longitud: 33,
      color: "rojo",
      unidad_medida: "m",
      categoria: "cables",
      precio_unitario: 8.0
    } ])

    expect(result.success?).to eq(true)
    articulo = Articulo.find_by!(nombre: "Cable Compra")
    expect(articulo.es_cable).to eq(true)
    expect(articulo.cantidad_en_stock).to eq(33)
    expect(articulo.precio_unitario).to eq(8.0)
    expect(articulo.stock_puntas.count).to eq(1)
    expect(result.movimiento.detalle_movimientos.first.precio_unitario).to eq(8.0)
  end

  it "rolls back movimiento, stock, and price when a later item is invalid" do
    articulo = create(:articulo, cantidad_en_stock: 5, precio_unitario: 100)

    expect {
      result = call_service(items: [
        { is_new: false, id_articulo: articulo.id_articulo, cantidad: 3, precio_unitario: 12 },
        valid_new_item.merge(precio_unitario: nil)
      ])
      expect(result.success?).to eq(false)
    }.not_to change(Movimiento, :count)

    articulo.reload
    expect(articulo.cantidad_en_stock).to eq(5)
    expect(articulo.precio_unitario).to eq(100)
  end
end
