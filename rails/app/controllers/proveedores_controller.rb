class ProveedoresController < ApplicationController
  before_action -> { authorize_page!("proveedores") }
  before_action :set_proveedor, only: %i[edit update]

  def index
    @proveedores = Proveedor.order(:nombre)
  end

  def new
    @proveedor = Proveedor.new
  end

  def create
    @proveedor = Proveedor.new(proveedor_params)
    if @proveedor.save
      redirect_to proveedores_path, notice: "Proveedor creado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @proveedor.update(proveedor_params)
      redirect_to proveedores_path, notice: "Proveedor actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_proveedor
    @proveedor = Proveedor.find(params[:id])
  end

  def proveedor_params
    params.require(:proveedor).permit(:nombre, :telefono, :email, :pagina_web, :direccion, :contacto, :notas)
  end
end
