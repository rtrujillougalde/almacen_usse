require "rails_helper"

RSpec.describe "Mi perfil", type: :request do
  let!(:user) { sign_in_as(:consulta) }

  it "shows the edit form" do
    get perfil_path
    expect(response).to have_http_status(:ok)
  end

  it "updates the name with the current password" do
    patch perfil_path, params: { user: { first_name: "Marta", last_name: "Ruiz", current_password: "password" } }

    expect(response).to redirect_to(perfil_path)
    expect(user.reload.full_name).to eq("Marta Ruiz")
  end

  it "refuses the change without the current password" do
    patch perfil_path, params: { user: { first_name: "Marta", last_name: "Ruiz", current_password: "nope" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(user.reload.first_name).to eq("Prueba")
  end

  it "changes the password and keeps the session signed in" do
    patch perfil_path, params: { user: { password: "nuevaclave1", password_confirmation: "nuevaclave1",
                                         current_password: "password" } }

    expect(response).to redirect_to(perfil_path)
    expect(user.reload.valid_password?("nuevaclave1")).to be(true)

    get perfil_path
    expect(response).to have_http_status(:ok)
  end

  it "cannot change the role or email from the profile" do
    patch perfil_path, params: { user: { role: "admin", email: "hack@usse.local", first_name: "Prueba",
                                         last_name: "Usuario", current_password: "password" } }

    expect(user.reload).to be_consulta
    expect(user.email).not_to eq("hack@usse.local")
  end
end
