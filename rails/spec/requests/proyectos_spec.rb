require "rails_helper"

RSpec.describe "Proyectos", type: :request do
  before { sign_in_as(:admin) }

  describe "GET /proyectos" do
    it "lists proyectos" do
      create(:proyecto, c_c: 4242, nombre_obra: "Obra Spec")
      get proyectos_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Obra Spec")
      expect(response.body).to include("4242")
    end
  end

  describe "POST /proyectos" do
    it "creates a proyecto" do
      expect {
        post proyectos_path, params: {
          proyecto: { c_c: 7777, nombre_obra: "Nueva Obra", encargado: "Ana" }
        }
      }.to change(Proyecto, :count).by(1)
      expect(response).to redirect_to(proyectos_path)
    end

    it "rejects duplicate c_c" do
      create(:proyecto, c_c: 8888)
      expect {
        post proyectos_path, params: {
          proyecto: { c_c: 8888, nombre_obra: "Dup", encargado: "Luis" }
        }
      }.not_to change(Proyecto, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
