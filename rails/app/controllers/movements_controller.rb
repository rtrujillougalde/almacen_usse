# Shared cart flow for entradas, compras and salidas.
#
# All three are the same sequence: open a cart, add items, finalize, confirm,
# create. The cart lives in the cookie session, mirroring the Streamlit app
# this replaced. Subclasses supply the route, the session key, the item
# builder, the service and their own wording:
#
#   MESSAGES                  frozen hash of the flash strings
#   movement_path             where every redirect goes
#   movement_tipo             the Movimiento enum value
#   cart_key                  the session key holding the cart
#   build_item                returns [CartItem, nil] or [nil, "message"]
#   service_class             the Movimientos service that persists it
#   header_validation_error   nil, or why the header is not ready
#
# Page authorization needs no hook: authorize_page! already defaults to
# controller_name, which is the page name for all three.
class MovementsController < ApplicationController
  before_action :authorize_page!
  # create is deliberately absent: it mutates the cart before rendering, so it
  # loads the page data itself once the new state is settled.
  before_action :load_page_data, only: %i[index add_item finalize]

  def index
  end

  def start
    open_cart!
    redirect_to movement_path
  end

  def add_item
    unless cart["open"]
      redirect_to movement_path, alert: messages[:not_started]
      return
    end

    sync_header_from_params!
    item, error = build_item
    if error
      flash.now[:alert] = error
      render :index, status: :unprocessable_content
      return
    end

    cart["items"] << item.to_h
    redirect_to movement_path, notice: messages[:item_added]
  end

  def remove_item
    idx = params[:index].to_i
    cart["items"].delete_at(idx) if idx >= 0 && idx < cart["items"].size
    redirect_to movement_path
  end

  def cancel
    reset_cart!
    redirect_to movement_path, notice: messages[:cancelled]
  end

  def finalize
    unless cart["open"]
      redirect_to movement_path, alert: messages[:none_in_progress]
      return
    end

    sync_header_from_params!

    if cart["items"].blank?
      flash.now[:alert] = "Debe agregar al menos un item"
      render :index, status: :unprocessable_content
      return
    end

    header_error = header_validation_error
    if header_error
      flash.now[:alert] = header_error
      render :index, status: :unprocessable_content
      return
    end

    cart["open"] = false
    cart["pending_confirmation"] = true
    redirect_to movement_path
  end

  def dismiss_confirmation
    cart["pending_confirmation"] = false
    cart["open"] = true
    redirect_to movement_path
  end

  def create
    unless cart["pending_confirmation"] && cart["items"].present?
      redirect_to movement_path, alert: messages[:nothing_pending]
      return
    end

    result = service_class.call(**service_args)

    if result.success?
      count = cart["items"].size
      reset_cart!
      redirect_to movement_path, notice: format(messages[:registered], count: count)
    else
      cart["pending_confirmation"] = false
      cart["open"] = true
      flash.now[:alert] = result.error
      load_page_data
      render :index, status: :unprocessable_content
    end
  end

  private

  def messages
    self.class::MESSAGES
  end

  def movement_path
    raise NotImplementedError
  end

  def movement_tipo
    raise NotImplementedError
  end

  def cart_key
    raise NotImplementedError
  end

  def build_item
    raise NotImplementedError
  end

  def service_class
    raise NotImplementedError
  end

  def header_validation_error
    raise NotImplementedError
  end

  # Compras add moneda and proveedor to this.
  def service_args
    {
      proyecto: Proyecto.find_by(id_proyecto: cart["id_proyecto"]),
      responsable: cart["responsable"],
      observaciones: cart["observaciones"].presence,
      items: cart_items_for_service
    }
  end

  def cart
    session[cart_key] ||= default_cart
  end

  def default_cart
    {
      "open" => false,
      "pending_confirmation" => false,
      "id_proyecto" => nil,
      "responsable" => "",
      "observaciones" => "",
      "items" => []
    }
  end

  def reset_cart!
    session[cart_key] = default_cart
  end

  def open_cart!
    session[cart_key] = default_cart.merge("open" => true)
  end

  def sync_header_from_params!
    cart["id_proyecto"] = params[:id_proyecto].presence
    cart["responsable"] = params[:responsable].to_s
    cart["observaciones"] = params[:observaciones].to_s
  end

  def cart_items_for_service
    cart["items"].map { |item| Movimientos::CartItem.new(item).to_service_args }
  end

  def load_page_data
    @proyectos = Proyecto.order(:c_c)
    @cart = cart
    @form_open = cart["open"] && !cart["pending_confirmation"]
    @pending_confirmation = cart["pending_confirmation"]
    @cart_items = cart["items"] || []
    @articulos = Articulo.alphabetical
    @recent = recent_movimientos
  end

  def recent_movimientos
    Movimiento.where(tipo: movement_tipo)
              .includes(*recent_includes)
              .order(fecha_hora: :desc)
              .limit(6)
  end

  def recent_includes
    [ :proyecto, { detalle_movimientos: [ :articulo, :stock_punta ] } ]
  end
end
