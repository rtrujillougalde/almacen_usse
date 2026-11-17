require "rails_helper"

RSpec.describe "Authentication and roles", type: :request do
  describe "unauthenticated access" do
    it "redirects root to sign in" do
      get root_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "login with email" do
    let!(:user) { create(:user, :admin, email: "boss@usse.local", password: "password") }

    it "signs in with email and password" do
      post user_session_path, params: { user: { email: "boss@usse.local", password: "password" } }
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Control de personal: Querétaro")
      expect(response.body).to include("Sistema de almacén")
    end

    it "does not sign in with the wrong password" do
      post user_session_path, params: { user: { email: "boss@usse.local", password: "wrong" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "post-login chooser" do
    it "sends unsigned visitors to sign in" do
      get control_personal_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "opens info general from the personnel button" do
      sign_in_as(:admin)
      get control_personal_path
      expect(response).to redirect_to(trabajadores_path)
      follow_redirect!
      expect(response.body).to include("Info general")
      expect(response.body).to include("Nuevo trabajador")
    end
  end

  describe "system access" do
    it "shows only the warehouse button for almacen access" do
      sign_in create(:user, :admin, :solo_almacen)

      get root_path
      expect(response.body).to include("Sistema de almacén")
      expect(response.body).not_to include("Control de personal: Querétaro")

      get control_personal_path
      expect(response).to redirect_to(inventario_path)
    end

    it "shows only the personnel button for personal access" do
      sign_in create(:user, :consulta, :solo_personal)

      get root_path
      expect(response.body).to include("Control de personal: Querétaro")
      expect(response.body).not_to include("Sistema de almacén")

      get inventario_path
      expect(response).to redirect_to(control_personal_path)
    end

    it "shows both buttons when access is ambos" do
      sign_in create(:user, :operador, acceso: :ambos)

      get root_path
      expect(response.body).to include("Control de personal: Querétaro")
      expect(response.body).to include("Sistema de almacén")
    end
  end

  describe "deactivated account" do
    let!(:user) { create(:user, :operador, :inactive, email: "ida@usse.local", password: "password") }

    it "cannot sign in" do
      post user_session_path, params: { user: { email: "ida@usse.local", password: "password" } }
      expect(response).not_to redirect_to(inventario_path)

      get inventario_path
      expect(response).to redirect_to(new_user_session_path)
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

      get usuarios_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "operador access" do
    before { sign_in_as(:operador) }

    it "allows the same pages as admin, except usuarios" do
      get inventario_path
      expect(response).to have_http_status(:ok)
      get entradas_path
      expect(response).to have_http_status(:ok)
      get compras_path
      expect(response).to have_http_status(:ok)
      get salidas_path
      expect(response).to have_http_status(:ok)
      get proveedores_path
      expect(response).to have_http_status(:ok)
      get proyectos_path
      expect(response).to have_http_status(:ok)
      get reportes_path
      expect(response).to have_http_status(:ok)
    end

    it "is redirected away from usuarios" do
      get usuarios_path
      expect(response).to redirect_to(inventario_path)
    end

    it "shows the same sidebar links as admin, without Usuarios" do
      get inventario_path
      expect(response.body).to include("Inventario")
      expect(response.body).to include("Entradas")
      expect(response.body).to include("Compras")
      expect(response.body).to include("Salidas")
      expect(response.body).to include("Proyectos")
      expect(response.body).to include("Reportes")
      expect(response.body).to include("Proveedores")
      expect(response.body).not_to include(usuarios_path)
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

    it "denies entradas compras salidas proveedores usuarios" do
      get entradas_path
      expect(response).to redirect_to(inventario_path)

      get compras_path
      expect(response).to redirect_to(inventario_path)

      get salidas_path
      expect(response).to redirect_to(inventario_path)

      get proveedores_path
      expect(response).to redirect_to(inventario_path)

      get usuarios_path
      expect(response).to redirect_to(inventario_path)
    end
  end
end
