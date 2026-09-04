class EntradasController < ApplicationController
  before_action -> { authorize_page!("entradas") }

  def index
    @proyectos = Proyecto.order(:c_c)
    @articulos = Articulo.order(:nombre)
    @recent = Movimiento.where(tipo: :entrada).includes(:proyecto, detalle_movimientos: :articulo).order(fecha_hora: :desc).limit(20)
  end

  def create
    proyecto = Proyecto.find(params[:id_proyecto])
    items = parsed_items
    result = Movimientos::CreateEntrada.call(
      proyecto: proyecto,
      responsable: params[:responsable],
      observaciones: params[:observaciones],
      items: items
    )

    if result.success?
      redirect_to entradas_path, notice: "Entrada ##{result.movimiento.id_movimiento} registrada."
    else
      @proyectos = Proyecto.order(:c_c)
      @articulos = Articulo.order(:nombre)
      @recent = Movimiento.where(tipo: :entrada).includes(:proyecto, detalle_movimientos: :articulo).order(fecha_hora: :desc).limit(20)
      flash.now[:alert] = result.error
      render :index, status: :unprocessable_entity
    end
  end

  private

  def parsed_items
    raw = params[:items]
    return [] if raw.blank?

    values = raw.respond_to?(:values) ? raw.values : Array(raw)
    values.filter_map do |item|
      h = item.permit(
        :is_new, :id_articulo, :nombre, :num_catalogo, :tipo, :precio_unitario,
        :unidad_medida, :categoria, :stock_minimo, :es_cable, :nombre_punta,
        :longitud, :cantidad, :color
      ).to_h.symbolize_keys
      h[:is_new] = ActiveModel::Type::Boolean.new.cast(h[:is_new])
      next if !h[:is_new] && h[:id_articulo].blank?
      next if h[:is_new] && h[:nombre].blank?
      h
    end
  end
end
