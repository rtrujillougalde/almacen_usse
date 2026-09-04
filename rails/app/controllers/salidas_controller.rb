class SalidasController < ApplicationController
  include MovementCartConcern

  before_action -> { authorize_page!("salidas") }
  before_action :load_page_data, only: %i[index create add_item finalize]

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

    cart["items"] << item
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

    if cart["responsable"].to_s.strip.blank?
      flash.now[:alert] = "Debe ingresar el responsable de la salida antes de finalizar"
      render :index, status: :unprocessable_entity
      return
    end

    if cart["items"].blank?
      flash.now[:alert] = "Debe agregar al menos un item"
      render :index, status: :unprocessable_entity
      return
    end

    if cart["id_proyecto"].blank?
      flash.now[:alert] = "Debe seleccionar un proyecto"
      render :index, status: :unprocessable_entity
      return
    end

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

    proyecto = Proyecto.find(cart["id_proyecto"])
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
      flash.now[:alert] = result.error
      render :index, status: :unprocessable_entity
    end
  end

  private

  def cart_key
    :salida_cart
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
                        .limit(5)
  end

  def build_salida_item
    id = params[:id_articulo]
    return [ nil, "Debe seleccionar un item" ] if id.blank?

    articulo = Articulo.find_by(id_articulo: id)
    return [ nil, "Artículo no encontrado" ] unless articulo

    if articulo.es_cable?
      id_punta = params[:id_punta].presence
      return [ nil, "Debe seleccionar una punta/carrete/tramo" ] if id_punta.blank?

      punta = StockPunta.find_by(id_punta: id_punta)
      return [ nil, "Punta no encontrada" ] unless punta
      return [ nil, "Punta no pertenece al artículo" ] unless punta.id_articulo == articulo.id_articulo
      return [ nil, "Punta ya utilizada en una salida" ] unless StockPunta.available.exists?(id_punta: punta.id_punta)

      if cart["items"].any? { |i| i["id_punta"].to_s == punta.id_punta.to_s }
        return [ nil, "Esa punta ya está en la salida actual" ]
      end

      item = {
        "nombre_item" => articulo.nombre,
        "id_articulo" => articulo.id_articulo,
        "es_cable" => true,
        "cantidad" => 0,
        "id_punta" => punta.id_punta,
        "nombre_punta" => punta.nombre_punta,
        "longitud" => punta.longitud.to_f
      }
    else
      cantidad = params[:cantidad].to_f
      stock = articulo.cantidad_en_stock.to_f
      errors = []
      errors << "La cantidad debe ser mayor a 0" if cantidad <= 0
      errors << "No hay suficiente stock (disponible: #{stock})" if cantidad > stock
      return [ nil, errors.join(". ") ] if errors.any?

      item = {
        "nombre_item" => articulo.nombre,
        "id_articulo" => articulo.id_articulo,
        "es_cable" => false,
        "cantidad" => cantidad,
        "id_punta" => nil
      }
    end

    [ item, nil ]
  end

  def cart_items_for_service
    cart["items"].map do |item|
      {
        id_articulo: item["id_articulo"],
        cantidad: item["cantidad"],
        id_punta: item["id_punta"]
      }
    end
  end
end
