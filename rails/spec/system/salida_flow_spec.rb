require "rails_helper"

RSpec.describe "Salida flow", type: :system do
  let!(:proyecto) { create(:proyecto) }

  it "registers a salida for a non-cable articulo" do
    articulo = create(:articulo, nombre: "Guantes", cantidad_en_stock: 8)
    sign_in_as(:operador)

    visit salidas_path
    click_button "Iniciar nueva salida"

    select proyecto.nombre_obra_with_cc, from: "id_proyecto"
    fill_in "responsable", with: "Ana"

    select articulo.nombre, from: "id_articulo"
    fill_in "cantidad", with: "2"
    click_button "Agregar item"

    expect(page).to have_content("Item agregado a la salida")
    expect(page).to have_content("Guantes")

    click_button "Finalizar salida"
    expect(page).to have_content("Confirmar salida")

    click_button "Aceptar"
    expect(page).to have_content("Salida registrada con 1 item(s)")

    expect(articulo.reload.cantidad_en_stock).to eq(6)
    expect(Movimiento.where(tipo: :salida).count).to eq(1)
  end

  it "registers a salida that consumes a whole punta" do
    cable = create(:articulo, :cable, nombre: "Cable Cobre", cantidad_en_stock: 30)
    punta = create(:stock_punta, articulo: cable, nombre_punta: "Carrete 3", longitud: 12)
    sign_in_as(:operador)

    visit salidas_path
    click_button "Iniciar nueva salida"

    select proyecto.nombre_obra_with_cc, from: "id_proyecto"
    fill_in "responsable", with: "Ana"

    select cable.nombre, from: "id_articulo"
    select "#{punta.nombre_punta} (#{punta.longitud}m)", from: "id_punta"
    click_button "Agregar item"

    expect(page).to have_content("Carrete 3")

    click_button "Finalizar salida"
    click_button "Aceptar"
    expect(page).to have_content("Salida registrada con 1 item(s)")

    expect(cable.reload.cantidad_en_stock).to eq(18)
    expect(StockPunta.available).not_to include(punta)
  end
end
