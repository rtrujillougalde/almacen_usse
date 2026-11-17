require "rails_helper"

RSpec.describe "Trabajadores", type: :request do
  before { sign_in_as(:admin) }

  describe "GET /trabajadores" do
    it "lists workers and the personnel menu" do
      grupo = Grupo.create!(nombre: "A")
      Trabajador.create!(nombre: "Ana López", grupo: grupo, curp: "LOPA800101MDFRRL09")

      get trabajadores_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Info general")
      expect(response.body).to include("Ana López")
      expect(response.body).to include("400")
      expect(response.body).to include("Editar")
      expect(response.body).to include("Ver documentos")
    end
  end

  describe "POST /trabajadores" do
    it "creates a worker and a new group" do
      expect {
        post trabajadores_path, params: {
          trabajador: { nombre: "Luis Mora", grupo_nombre: "B", tipo_sangre: "o_positivo", activo: "1" }
        }
      }.to change(Trabajador, :count).by(1)

      expect(response).to redirect_to(trabajadores_path)
      trabajador = Trabajador.find_by!(nombre: "Luis Mora")
      expect(trabajador.grupo.nombre).to eq("B")
      expect(trabajador).to be_o_positivo
      expect(trabajador.id_usse).to eq(400)
    end

    it "rejects a missing group" do
      expect {
        post trabajadores_path, params: { trabajador: { nombre: "Luis Mora", grupo_nombre: "" } }
      }.not_to change(Trabajador, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /trabajadores/:id" do
    it "updates the worker" do
      trabajador = Trabajador.create!(nombre: "Ana", grupo: Grupo.create!(nombre: "A"))

      patch trabajador_path(trabajador), params: {
        trabajador: { nombre: "Ana Actualizada", grupo_nombre: "A", activo: "1" }
      }

      expect(response).to redirect_to(trabajadores_path)
      expect(trabajador.reload.nombre).to eq("Ana Actualizada")
    end
  end

  it "blocks warehouse-only users" do
    sign_in create(:user, :operador, :solo_almacen)

    get trabajadores_path

    expect(response).to redirect_to(inventario_path)
  end
end
