class ProyectosController < ApplicationController
  before_action -> { authorize_page!("proyectos") }

  def index
    @proyectos = Proyecto.order(:c_c)
    @proyecto = Proyecto.new
  end

  def create
    @proyecto = Proyecto.new(proyecto_params)
    if @proyecto.save
      redirect_to proyectos_path, notice: "Proyecto creado."
    else
      @proyectos = Proyecto.order(:c_c)
      flash.now[:alert] = @proyecto.errors.full_messages.to_sentence
      render :index, status: :unprocessable_entity
    end
  end

  private

  def proyecto_params
    params.require(:proyecto).permit(:c_c, :nombre_obra, :encargado)
  end
end
