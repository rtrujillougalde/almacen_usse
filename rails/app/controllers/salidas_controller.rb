class SalidasController < ApplicationController
  include MovementCartConcern

  before_action -> { authorize_page!("salidas") }
  # create is deliberately absent: it mutates the cart before rendering, so it
  # loads the page data itself once the new state is settled.
  before_action :load_page_data, only: %i[index add_item finalize]

  def index
  end

  def start
    open_cart!
    redirect_to salidas_path
  end

  def add_item
    unless cart["open"]
      redirect_to salidas_path, alert: "Inicia una nueva salida primero."
      return
    end

    sync_header_from_params!
    item, error = build_salida_item
    if error
      flash.now[:alert] = error
      render :index, status: :unprocessable_entity
      return
    end

    cart["items"] << item.to_h
    redirect_to salidas_path, notice: "Item agregado a la salida."
  end

  def remove_item
    idx = params[:index].to_i
    cart["items"].delete_at(idx) if idx >= 0 && idx < cart["items"].size
    redirect_to salidas_path
  end

  def cancel
    reset_cart!
    redirect_to salidas_path, notice: "Salida cancelada."
  end

  def finalize
    unless cart["open"]
      redirect_to salidas_path, alert: "No hay una salida en curso."
      return
    end

    sync_header_from_params!

    if cart["items"].blank?
      flash.now[:alert] = "Debe agregar al menos un item"
      render :index, status: :unprocessable_entity
      return
    end

    header_error = header_validation_error
    if header_error
      flash.now[:alert] = header_error
      render :index, status: :unprocessable_entity
      return
    end

    cart["open"] = false
    cart["pending_confirmation"] = true
    redirect_to salidas_path
  end

  def dismiss_confirmation
    cart["pending_confirmation"] = false
    cart["open"] = true
    redirect_to salidas_path
  end

  def create
    unless cart["pending_confirmation"] && cart["items"].present?
      redirect_to salidas_path, alert: "No hay una salida pendiente de confirmación."
      return
    end

    proyecto = Proyecto.find_by(id_proyecto: cart["id_proyecto"])
    result = Movimientos::CreateSalida.call(
      proyecto: proyecto,
      responsable: cart["responsable"],
      observaciones: cart["observaciones"].presence,
      items: cart_items_for_service
    )

    if result.success?
      count = cart["items"].size
      reset_cart!
      redirect_to salidas_path, notice: "Salida registrada con #{count} item(s)"
    else
      cart["pending_confirmation"] = false
      cart["open"] = true
      flash.now[:alert] = result.error
      load_page_data
      render :index, status: :unprocessable_entity
    end
  end

  private

  def build_salida_item
    Movimientos::SalidaItemBuilder.call(params, cart_items: cart["items"])
  end

  def cart_key
    :salida_cart
  end

  def header_validation_error
    return "Debe ingresar el responsable de la salida antes de finalizar" if cart["responsable"].to_s.strip.blank?
    return "Debe seleccionar un proyecto" if cart["id_proyecto"].blank?

    nil
  end

  def load_page_data
    load_common_form_data!
    @articulos = Articulo.order(:nombre)
    reserved_punta_ids = cart["items"].filter_map { |i| i["id_punta"] }
    @available_puntas = StockPunta.available.includes(:articulo)
    @available_puntas = @available_puntas.where.not(id_punta: reserved_punta_ids) if reserved_punta_ids.any?
    @puntas_by_articulo = @available_puntas.group_by(&:id_articulo)
    @recent = Movimiento.where(tipo: :salida)
                        .includes(:proyecto, detalle_movimientos: [ :articulo, :stock_punta ])
                        .order(fecha_hora: :desc)
                        .limit(6)
  end
end
