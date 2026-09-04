require "rails_helper"

RSpec.describe "Salidas", type: :request do
  let!(:proyecto) { create(:proyecto) }
  let!(:articulo) { create(:articulo, cantidad_en_stock: 8) }

  it "allows operador to register a salida via cart flow" do
    sign_in_as(:operador)

    post start_salidas_path
    expect(response).to redirect_to(salidas_path)

    post add_item_salidas_path, params: {
      id_proyecto: proyecto.id_proyecto,
      responsable: "Op",
      id_articulo: articulo.id_articulo,
      cantidad: "2"
    }
    expect(response).to redirect_to(salidas_path)
    expect(session[:salida_cart]["items"].size).to eq(1)

    post finalize_salidas_path, params: {
      id_proyecto: proyecto.id_proyecto,
      responsable: "Op"
    }
    expect(session[:salida_cart]["pending_confirmation"]).to eq(true)

    expect {
      post salidas_path
    }.to change(Movimiento.where(tipo: :salida), :count).by(1)
    expect(response).to redirect_to(salidas_path)
    expect(articulo.reload.cantidad_en_stock).to eq(6)
  end

  it "forbids consulta from salidas" do
    sign_in_as(:consulta)
    get salidas_path
    expect(response).to redirect_to(inventario_path)
  end
end
