require "rails_helper"

RSpec.describe "Compra flow", type: :system do
  let!(:proyecto) { create(:proyecto) }
  let!(:proveedor) { create(:proveedor, nombre: "Ferreteria Sur") }

  it "registers a compra for a brand new item" do
    sign_in_as(:operador)

    visit compras_path
    click_button "Iniciar nueva compra"

    select proyecto.nombre_obra_with_cc, from: "id_proyecto"
    select "MXN", from: "moneda"
    select proveedor.nombre, from: "id_proveedor"
    fill_in "responsable", with: "Ana"

    select "Otro (escribir nuevo)", from: "id_articulo"
    fill_in "nombre", with: "Taladro"
    select "herramienta", from: "tipo"
    select "general", from: "categoria"
    fill_in "cantidad", with: "2"
    fill_in "precio_unitario", with: "1250.50"
    click_button "Agregar item"

    expect(page).to have_content("Item agregado a la compra")
    expect(page).to have_content("Taladro")

    click_button "Finalizar compra"
    expect(page).to have_content("Confirmar compra")

    click_button "Aceptar"
    expect(page).to have_content("Compra registrada con 1 item(s)")

    articulo = Articulo.find_by!(nombre: "Taladro")
    expect(articulo.cantidad_en_stock).to eq(2)
    expect(articulo.precio_unitario).to eq(1250.50)

    movimiento = Movimiento.where(tipo: :compra).sole
    expect(movimiento.moneda).to eq("MXN")
    expect(movimiento.proveedor).to eq(proveedor)
    expect(movimiento.detalle_movimientos.sole.precio_unitario).to eq(1250.50)
  end

  it "restocks an existing articulo and updates its price" do
    articulo = create(:articulo, nombre: "Cable UTP", cantidad_en_stock: 5, precio_unitario: 100)
    sign_in_as(:operador)

    visit compras_path
    click_button "Iniciar nueva compra"

    select proyecto.nombre_obra_with_cc, from: "id_proyecto"
    select "USD", from: "moneda"
    select proveedor.nombre, from: "id_proveedor"
    fill_in "responsable", with: "Ana"

    select articulo.nombre, from: "id_articulo"
    fill_in "cantidad", with: "3"
    fill_in "precio_unitario", with: "12.25"
    click_button "Agregar item"

    click_button "Finalizar compra"
    click_button "Aceptar"
    expect(page).to have_content("Compra registrada con 1 item(s)")

    articulo.reload
    expect(articulo.cantidad_en_stock).to eq(8)
    expect(articulo.precio_unitario).to eq(12.25)
  end
end
