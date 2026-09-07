require "rails_helper"

RSpec.describe "Authentication and roles", type: :request do
  describe "unauthenticated access" do
    it "redirects root to sign in" do
      get root_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "login with username" do
    let!(:user) { create(:user, :admin, username: "boss", email: "boss@usse.local", password: "password") }

    it "signs in with username and password" do
      post user_session_path, params: { user: { username: "boss", password: "password" } }
      expect(response).to redirect_to(inventario_path)
      follow_redirect!
      expect(response).to have_http_status(:ok)
    end
  end

  describe "admin access" do
    before { sign_in_as(:admin) }

    it "allows proveedores and proyectos" do
      get proveedores_path
      expect(response).to have_http_status(:ok)

      get proyectos_path
      expect(response).to have_http_status(:ok)

      get entradas_path
      expect(response).to have_http_status(:ok)

      get compras_path
      expect(response).to have_http_status(:ok)

      get reportes_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "operador access" do
    before { sign_in_as(:operador) }

    it "allows inventario entradas compras salidas" do
      get inventario_path
      expect(response).to have_http_status(:ok)
      get entradas_path
      expect(response).to have_http_status(:ok)
      get compras_path
      expect(response).to have_http_status(:ok)
      get salidas_path
      expect(response).to have_http_status(:ok)
    end

    it "denies proveedores and proyectos and reportes" do
      get proveedores_path
      expect(response).to redirect_to(inventario_path)

      get proyectos_path
      expect(response).to redirect_to(inventario_path)

      get reportes_path
      expect(response).to redirect_to(inventario_path)
    end
  end

  describe "consulta access" do
    before { sign_in_as(:consulta) }

    it "allows inventario and reportes" do
      get inventario_path
      expect(response).to have_http_status(:ok)
      get reportes_path
      expect(response).to have_http_status(:ok)
    end

    it "denies entradas compras salidas proveedores" do
      get entradas_path
      expect(response).to redirect_to(inventario_path)

      get compras_path
      expect(response).to redirect_to(inventario_path)

      get salidas_path
      expect(response).to redirect_to(inventario_path)

      get proveedores_path
      expect(response).to redirect_to(inventario_path)
    end
  end
end
