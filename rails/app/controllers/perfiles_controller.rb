class PerfilesController < ApplicationController
  def edit
    @usuario = current_user
  end

  def update
    @usuario = current_user

    if @usuario.update_with_password(perfil_params)
      bypass_sign_in(@usuario)
      redirect_to perfil_path, notice: "Perfil actualizado."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def perfil_params
    params.require(:user).permit(:first_name, :last_name, :password, :password_confirmation, :current_password)
  end
end
