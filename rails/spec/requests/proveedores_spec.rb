require "rails_helper"

RSpec.describe "Proveedores", type: :request do
  before { sign_in_as(:admin) }

  describe "GET /proveedores" do
    it "lists proveedores" do
      create(:proveedor, nombre: "ACME Test")
      get proveedores_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ACME Test")
    end
  end

  describe "POST /proveedores" do
    it "creates a proveedor" do
      expect {
        post proveedores_path, params: {
          proveedor: {
            nombre: "Nuevo Prov",
            telefono: "111",
            email: "a@b.com",
            pagina_web: "https://x.com",
            direccion: "Dir",
            contacto: "Cont",
            notas: "N"
          }
        }
      }.to change(Proveedor, :count).by(1)

      expect(response).to redirect_to(proveedores_path)
      expect(Proveedor.order(:id_proveedor).last.nombre).to eq("Nuevo Prov")
    end

    it "rejects missing nombre" do
      expect {
        post proveedores_path, params: { proveedor: { nombre: "" } }
      }.not_to change(Proveedor, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /proveedores/:id" do
    it "updates a proveedor" do
      proveedor = create(:proveedor, nombre: "Old")
      patch proveedor_path(proveedor), params: { proveedor: { nombre: "Updated" } }
      expect(response).to redirect_to(proveedores_path)
      expect(proveedor.reload.nombre).to eq("Updated")
    end
  end

  it "does not define a destroy route" do
    expect(Rails.application.routes.routes.none? { |r|
      r.defaults[:controller] == "proveedores" && r.defaults[:action] == "destroy"
    }).to eq(true)
  end
end
