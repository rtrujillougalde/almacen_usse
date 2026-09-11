require "rails_helper"

RSpec.describe "Entrada flow", type: :system do
  let!(:proyecto) { create(:proyecto) }

  it "registers an entrada for a brand new item" do
    sign_in_as(:operador)

    visit entradas_path
    click_button "Iniciar nueva entrada"

    select proyecto.nombre_obra_with_cc, from: "id_proyecto"
    fill_in "responsable", with: "Ana"

    select "Otro (escribir nuevo)", from: "id_articulo"
    fill_in "nombre", with: "Cinta Aislante"
    select "general", from: "categoria"
    fill_in "cantidad", with: "6"
    click_button "Agregar item"

    expect(page).to have_content("Item agregado a la entrada")
    expect(page).to have_content("Cinta Aislante")

    click_button "Finalizar entrada"
    expect(page).to have_content("Confirmar entrada")

    click_button "Aceptar"
    expect(page).to have_content("Movimiento registrado con 1 item(s)")

    articulo = Articulo.find_by!(nombre: "Cinta Aislante")
    expect(articulo.cantidad_en_stock).to eq(6)
    expect(Movimiento.where(tipo: :entrada).count).to eq(1)
  end

  it "registers an entrada that adds a punta to an existing cable" do
    cable = create(:articulo, :cable, nombre: "Cable Cobre", cantidad_en_stock: 100)
    sign_in_as(:operador)

    visit entradas_path
    click_button "Iniciar nueva entrada"

    select proyecto.nombre_obra_with_cc, from: "id_proyecto"
    fill_in "responsable", with: "Ana"

    select cable.nombre, from: "id_articulo"
    fill_in "nombre_punta", with: "Carrete 7"
    fill_in "longitud", with: "20"
    click_button "Agregar item"

    expect(page).to have_content("Carrete 7")

    click_button "Finalizar entrada"
    expect(page).to have_content("Confirmar entrada")

    click_button "Aceptar"
    expect(page).to have_content("Movimiento registrado con 1 item(s)")

    expect(cable.reload.cantidad_en_stock).to eq(120)
    expect(cable.stock_puntas.sole.nombre_punta).to eq("Carrete 7")
  end
end
