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

  it "forbids consulta from entradas" do
    sign_in_as(:consulta)
    get entradas_path
    expect(response).to redirect_to(inventario_path)
  end
end
