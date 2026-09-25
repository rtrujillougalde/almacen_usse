class ComprasController < ApplicationController
  include MovementCartConcern

  before_action -> { authorize_page!("compras") }
  # create is deliberately absent: it mutates the cart before rendering, so it
  # loads the page data itself once the new state is settled.
  before_action :load_page_data, only: %i[index add_item finalize]

  def index
  end

  def start
    open_cart!
    redirect_to compras_path
  end

  def add_item
    unless cart["open"]
      redirect_to compras_path, alert: "Inicia una nueva compra primero."
      return
    end

    sync_header_from_params!
    item, error = build_compra_item
    if error
      flash.now[:alert] = error
      render :index, status: :unprocessable_entity
      return
    end

    cart["items"] << item.to_h
    redirect_to compras_path, notice: "Item agregado a la compra."
  end

  def remove_item
    idx = params[:index].to_i
    cart["items"].delete_at(idx) if idx >= 0 && idx < cart["items"].size
    redirect_to compras_path
  end

  def cancel
    reset_cart!
    redirect_to compras_path, notice: "Compra cancelada."
  end

  def finalize
    unless cart["open"]
      redirect_to compras_path, alert: "No hay una compra en curso."
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
    redirect_to compras_path
  end

  def dismiss_confirmation
    cart["pending_confirmation"] = false
    cart["open"] = true
    redirect_to compras_path
  end

  def create
    unless cart["pending_confirmation"] && cart["items"].present?
      redirect_to compras_path, alert: "No hay una compra pendiente de confirmación."
      return
    end

    proyecto = Proyecto.find_by(id_proyecto: cart["id_proyecto"])
    proveedor = Proveedor.find_by(id_proveedor: cart["id_proveedor"])
    result = Movimientos::CreateCompra.call(
      proyecto: proyecto,
      moneda: cart["moneda"],
      proveedor: proveedor,
      responsable: cart["responsable"],
      observaciones: cart["observaciones"].presence,
      items: cart_items_for_service
    )

    if result.success?
      count = cart["items"].size
      reset_cart!
      redirect_to compras_path, notice: "Compra registrada con #{count} item(s)"
    else
      cart["pending_confirmation"] = false
      cart["open"] = true
      flash.now[:alert] = result.error
      load_page_data
      render :index, status: :unprocessable_entity
    end
  end

  private

  def build_compra_item
    Movimientos::CompraItemBuilder.call(params, cart_items: cart["items"])
  end

  def cart_key
    :compra_cart
  end

  def default_cart
    super.merge("moneda" => nil, "id_proveedor" => nil)
  end

  def sync_header_from_params!
    super
    cart["moneda"] = params[:moneda].presence
    cart["id_proveedor"] = params[:id_proveedor].presence
  end

  def load_page_data
    load_common_form_data!
    @articulos = Articulo.order(:nombre)
    @proveedores = Proveedor.order(:nombre)
    @recent = Movimiento.where(tipo: :compra)
                        .includes(:proyecto, :proveedor, detalle_movimientos: [ :articulo, :stock_punta ])
                        .order(fecha_hora: :desc)
                        .limit(6)
  end

  def header_validation_error
    return "Responsable es obligatorio" if cart["responsable"].to_s.strip.blank?
    return "Proyecto es obligatorio" if cart["id_proyecto"].blank?
    return "Moneda es obligatoria" if cart["moneda"].blank?
    return "Moneda inválida" unless Movimiento::MONEDAS.include?(cart["moneda"].to_s)
    return "Proveedor es obligatorio" if cart["id_proveedor"].blank?

    nil
  end
end
