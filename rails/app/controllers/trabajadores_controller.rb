class TrabajadoresController < ApplicationController
  layout "personal"

  before_action -> { require_system!(:personal) }
  before_action :set_trabajador, only: %i[edit update]

  def index
    @trabajadores = Trabajador.includes(:grupo).order(:id_usse)
  end

  def new
    @trabajador = Trabajador.new(activo: true)
  end

  def create
    @trabajador = Trabajador.new(trabajador_params)
    save_trabajador(:new)
  end

  def edit
  end

  def update
    @trabajador.assign_attributes(trabajador_params)
    save_trabajador(:edit)
  end

  private

  def set_trabajador
    @trabajador = Trabajador.find(params[:id])
  end

  def save_trabajador(template)
    return render template, status: :unprocessable_content unless assign_grupo

    if @trabajador.save
      redirect_to trabajadores_path, notice: template == :new ? "Trabajador creado." : "Trabajador actualizado."
    else
      render template, status: :unprocessable_content
    end
  end

  def assign_grupo
    nombre = params.dig(:trabajador, :grupo_nombre).to_s.strip
    if nombre.blank?
      @trabajador.errors.add(:grupo, "no puede estar en blanco")
      return false
    end

    @trabajador.grupo = Grupo.find_or_create_by!(nombre: nombre)
    true
  end

  def trabajador_params
    attrs = params.require(:trabajador).permit(
      :nombre, :cel_personal, :cel_emergencia, :curp, :puesto_magnet,
      :especialidad_obra, :puesto_imss, :credencial_ingreso, :rfc,
      :antidoping, :tipo_sangre, :activo
    )
    attrs[:antidoping] = nil if attrs[:antidoping].blank?
    attrs[:tipo_sangre] = nil if attrs[:tipo_sangre].blank?
    attrs
  end
end
