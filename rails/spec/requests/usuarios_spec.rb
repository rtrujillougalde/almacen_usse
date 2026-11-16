require "rails_helper"

RSpec.describe "Usuarios admin", type: :request do
  let!(:admin) { sign_in_as(:admin) }

  describe "GET /usuarios" do
    it "lists accounts with their full name and role" do
      create(:user, :operador, first_name: "Luis", last_name: "Mora")

      get usuarios_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Luis Mora")
      expect(response.body).to include("Operador")
    end
  end

  describe "POST /usuarios" do
    let(:params) do
      { user: { first_name: "Ana", last_name: "López", email: "ana@usse.local", role: "operador",
                password: "secret123", password_confirmation: "secret123" } }
    end

    it "creates an account with the chosen role" do
      expect { post usuarios_path, params: params }.to change(User, :count).by(1)

      expect(response).to redirect_to(usuarios_path)
      expect(User.find_by(email: "ana@usse.local")).to be_operador
    end

    it "rejects a missing name" do
      params[:user][:first_name] = ""

      expect { post usuarios_path, params: params }.not_to change(User, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /usuarios/:id" do
    let!(:target) { create(:user, :consulta, email: "t@usse.local", password: "password") }

    it "changes the role and keeps the password when the field is blank" do
      patch usuario_path(target), params: { user: { first_name: "Nueva", last_name: "Persona", email: target.email,
                                                     role: "operador", password: "", password_confirmation: "" } }

      expect(response).to redirect_to(usuarios_path)
      expect(target.reload).to be_operador
      expect(target.valid_password?("password")).to be(true)
    end

    it "does not let an admin remove their own admin role" do
      patch usuario_path(admin), params: { user: { first_name: admin.first_name, last_name: admin.last_name,
                                                   email: admin.email, role: "consulta" } }

      expect(response).to redirect_to(edit_usuario_path(admin))
      expect(admin.reload).to be_admin
    end
  end

  describe "deactivate and reactivate" do
    let!(:target) { create(:user, :operador) }

    it "deactivates another account" do
      patch deactivate_usuario_path(target)

      expect(target.reload).not_to be_active
    end

    it "reactivates a deactivated account" do
      target.update!(active: false)

      patch reactivate_usuario_path(target)

      expect(target.reload).to be_active
    end

    it "does not let an admin deactivate their own account" do
      patch deactivate_usuario_path(admin)

      expect(admin.reload).to be_active
    end
  end
end
