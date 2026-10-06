require "rails_helper"

RSpec.describe "Proveedores", type: :request do
  before { sign_in_as(:admin) }

  it "renders index with new proveedor link" do
    get proveedores_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Nuevo proveedor")
    expect(response.body).to include(new_proveedor_path)
  end

  describe "GET /proveedores" do
    it "lists proveedores" do
      create(:proveedor, nombre: "ACME Test")
      get proveedores_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ACME Test")
    end

    it "shows the delivery minimum" do
      create(:proveedor, nombre: "Entrega SA", entrega_estado: "ofrecida", entrega_monto_minimo: 1500, entrega_moneda: "MXN")
      get proveedores_path
      expect(response.body).to include("Desde $1500.00 MXN")
    end

    it "shows notas" do
      create(:proveedor, nombre: "Notas SA", notas: "Zona norte sin entrega")
      get proveedores_path
      expect(response.body).to include("Zona norte sin entrega")
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

    it "stores an offered delivery minimum" do
      post proveedores_path, params: {
        proveedor: {
          nombre: "Con Entrega",
          entrega_estado: "ofrecida",
          entrega_monto_minimo: "1500",
          entrega_moneda: "MXN"
        }
      }

      proveedor = Proveedor.order(:id_proveedor).last
      expect(proveedor.entrega_estado).to eq("ofrecida")
      expect(proveedor.entrega_monto_minimo).to eq(1500)
      expect(proveedor.entrega_moneda).to eq("MXN")
    end

    it "rejects missing nombre" do
      expect {
        post proveedores_path, params: { proveedor: { nombre: "" } }
      }.not_to change(Proveedor, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /proveedores/:id" do
    it "updates a proveedor" do
      proveedor = create(:proveedor, nombre: "Old")
      patch proveedor_path(proveedor), params: { proveedor: { nombre: "Updated" } }
      expect(response).to redirect_to(proveedores_path)
      expect(proveedor.reload.nombre).to eq("Updated")
    end

    it "clears the delivery minimum when delivery is no longer offered" do
      proveedor = create(:proveedor, entrega_estado: "ofrecida", entrega_monto_minimo: 1500, entrega_moneda: "MXN")

      patch proveedor_path(proveedor), params: { proveedor: { entrega_estado: "no_ofrecida" } }

      proveedor.reload
      expect(proveedor.entrega_estado).to eq("no_ofrecida")
      expect(proveedor.entrega_monto_minimo).to be_nil
      expect(proveedor.entrega_moneda).to be_nil
    end
  end

  it "does not define a destroy route" do
    expect(Rails.application.routes.routes.none? { |r|
      r.defaults[:controller] == "proveedores" && r.defaults[:action] == "destroy"
    }).to eq(true)
  end
end
