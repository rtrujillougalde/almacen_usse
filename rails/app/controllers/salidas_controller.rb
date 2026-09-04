class SalidasController < ApplicationController
  before_action -> { authorize_page!("salidas") }

  def index
    @proyectos = Proyecto.order(:c_c)
    @articulos = Articulo.order(:nombre)
    @puntas_by_articulo = StockPunta.available.includes(:articulo).group_by(&:id_articulo)
    @recent = Movimiento.where(tipo: :salida).includes(:proyecto, detalle_movimientos: :articulo).order(fecha_hora: :desc).limit(20)
  end

  def create
    proyecto = Proyecto.find(params[:id_proyecto])
    items = parsed_items
    result = Movimientos::CreateSalida.call(
      proyecto: proyecto,
      responsable: params[:responsable],
      observaciones: params[:observaciones],
      items: items
    )

    if result.success?
      redirect_to salidas_path, notice: "Salida ##{result.movimiento.id_movimiento} registrada."
    else
      index
      flash.now[:alert] = result.error
      render :index, status: :unprocessable_entity
    end
  end

  private

  def parsed_items
    Array(params[:items]).filter_map do |raw|
      h = raw.permit(:id_articulo, :cantidad, :id_punta).to_h.symbolize_keys
      next if h[:id_articulo].blank?
      h
    end
  end
end
