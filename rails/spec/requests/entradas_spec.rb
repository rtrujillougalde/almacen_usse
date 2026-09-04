require "rails_helper"

RSpec.describe "Entradas", type: :request do
  let!(:proyecto) { create(:proyecto) }

  it "allows operador to register an entrada" do
    sign_in_as(:operador)
    expect {
      post entradas_path, params: {
        id_proyecto: proyecto.id_proyecto,
        responsable: "Op",
        items: {
          "0" => { is_new: "1", nombre: "Item Entrada", tipo: "material", cantidad: "4", unidad_medida: "pza", categoria: "general" }
        }
      }
    }.to change(Movimiento, :count).by(1)
    expect(response).to redirect_to(entradas_path)
  end

  it "forbids consulta from entradas" do
    sign_in_as(:consulta)
    get entradas_path
    expect(response).to redirect_to(inventario_path)
  end
end
