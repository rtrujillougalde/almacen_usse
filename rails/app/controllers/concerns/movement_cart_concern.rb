# Shared session-cart helpers for Entradas / Salidas (mirrors Streamlit session_state).
module MovementCartConcern
  extend ActiveSupport::Concern

  private

  def cart_key
    raise NotImplementedError
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

  def load_common_form_data!
    @proyectos = Proyecto.order(:c_c)
    @cart = cart
    @form_open = cart["open"] && !cart["pending_confirmation"]
    @pending_confirmation = cart["pending_confirmation"]
    @cart_items = cart["items"] || []
  end
end
