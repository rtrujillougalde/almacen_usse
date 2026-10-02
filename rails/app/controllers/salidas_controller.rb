class SalidasController < MovementsController
  MESSAGES = {
    not_started: "Inicia una nueva salida primero.",
    item_added: "Item agregado a la salida.",
    cancelled: "Salida cancelada.",
    none_in_progress: "No hay una salida en curso.",
    nothing_pending: "No hay una salida pendiente de confirmación.",
    registered: "Salida registrada con %{count} item(s)"
  }.freeze

  private

  def movement_path
    salidas_path
  end

  def movement_tipo
    :salida
  end

  def cart_key
    :salida_cart
  end

  def build_item
    Movimientos::SalidaItemBuilder.call(params, cart_items: cart["items"])
  end

  def service_class
    Movimientos::CreateSalida
  end

  def header_validation_error
    return "Debe ingresar el responsable de la salida antes de finalizar" if cart["responsable"].to_s.strip.blank?
    return "Debe seleccionar un proyecto" if cart["id_proyecto"].blank?

    nil
  end

  # A punta already in the cart is no longer offered, so the same reel cannot
  # be picked twice before the salida is confirmed.
  def load_page_data
    super
    reserved_punta_ids = cart["items"].filter_map { |i| i["id_punta"] }
    @available_puntas = StockPunta.available.includes(:articulo)
    @available_puntas = @available_puntas.where.not(id_punta: reserved_punta_ids) if reserved_punta_ids.any?
    @puntas_by_articulo = @available_puntas.group_by(&:id_articulo)
  end
end
