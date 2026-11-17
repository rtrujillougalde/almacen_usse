class UsuariosController < ApplicationController
  before_action :authorize_page!
  before_action :set_usuario, only: %i[edit update deactivate reactivate]

  def index
    @usuarios = User.order(:first_name, :last_name)
  end

  def new
    @usuario = User.new(role: "consulta")
  end

  def create
    @usuario = User.new(usuario_params)
    if @usuario.save
      redirect_to usuarios_path, notice: "Usuario creado."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    attrs = usuario_params
    attrs = attrs.except(:password, :password_confirmation) if attrs[:password].blank?

    if self_demotion?(attrs[:role])
      return redirect_to edit_usuario_path(@usuario), alert: "No puedes quitarte a ti mismo el rol de administrador."
    end

    if self_almacen_lockout?(attrs[:acceso])
      return redirect_to edit_usuario_path(@usuario), alert: "No puedes quitarte el acceso al sistema de almacén."
    end

    if @usuario.update(attrs)
      redirect_to usuarios_path, notice: "Usuario actualizado."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def deactivate
    return redirect_to usuarios_path, alert: "No puedes desactivar tu propia cuenta." if @usuario == current_user

    if @usuario.update(active: false)
      redirect_to usuarios_path, notice: "Usuario desactivado."
    else
      redirect_to usuarios_path, alert: @usuario.errors.full_messages.to_sentence
    end
  end

  def reactivate
    if @usuario.update(active: true)
      redirect_to usuarios_path, notice: "Usuario reactivado."
    else
      redirect_to usuarios_path, alert: @usuario.errors.full_messages.to_sentence
    end
  end

  private

  def set_usuario
    @usuario = User.find(params[:id])
  end

  def self_demotion?(new_role)
    @usuario == current_user && new_role.present? && new_role != "admin"
  end

  def self_almacen_lockout?(new_acceso)
    @usuario == current_user && new_acceso.present? && new_acceso == "personal"
  end

  def usuario_params
    params.require(:user).permit(:first_name, :last_name, :email, :role, :acceso, :password, :password_confirmation)
  end
end
