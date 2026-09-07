require "rails_helper"

RSpec.describe "Entradas", type: :request do
  let!(:proyecto) { create(:proyecto) }

  it "allows operador to register an entrada via cart flow" do
    sign_in_as(:operador)

    post start_entradas_path
    expect(response).to redirect_to(entradas_path)

    expect {
      post add_item_entradas_path, params: {
        id_proyecto: proyecto.id_proyecto,
        responsable: "Op",
        id_articulo: "__new__",
        nombre: "Item Entrada",
        tipo: "material",
        cantidad: "4",
        unidad_medida: "pza",
        categoria: "general"
      }
    }.to change { session[:entrada_cart]["items"].size }.by(1)
    expect(response).to redirect_to(entradas_path)

    post finalize_entradas_path, params: {
      id_proyecto: proyecto.id_proyecto,
      responsable: "Op"
    }
    expect(response).to redirect_to(entradas_path)
    expect(session[:entrada_cart]["pending_confirmation"]).to eq(true)

    expect {
      post entradas_path
    }.to change(Movimiento, :count).by(1)
    expect(response).to redirect_to(entradas_path)
  end

  it "renders recent entradas as cards with a bold cost center" do
    sign_in_as(:operador)
    articulo = create(:articulo, nombre: "Cable Reciente")
    movimiento = create(
      :movimiento,
      tipo: :entrada,
      proyecto: proyecto,
      responsable: "Ana",
      fecha_hora: Time.zone.parse("2026-09-07 15:42")
    )
    create(:detalle_movimiento, movimiento: movimiento, articulo: articulo, cantidad: 3)

    get entradas_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("movement-card")
    expect(response.body).to include("6 últimos")
    expect(response.body).to include("col-xl-4")
    expect(response.body).to include("C.C. #{proyecto.c_c}")
    expect(response.body).to include("badge-usse")
    expect(response.body).not_to include("##{movimiento.id_movimiento}")
    expect(response.body).to include(proyecto.nombre_obra)
    expect(response.body).to include("Cable Reciente")
  end

  it "forbids consulta from entradas" do
    sign_in_as(:consulta)
    get entradas_path
    expect(response).to redirect_to(inventario_path)
  end
end
