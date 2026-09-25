class EntradasController < MovementsController
  MESSAGES = {
    not_started: "Inicia una nueva entrada primero.",
    item_added: "Item agregado a la entrada.",
    cancelled: "Entrada cancelada.",
    none_in_progress: "No hay una entrada en curso.",
    nothing_pending: "No hay una entrada pendiente de confirmación.",
    registered: "Movimiento registrado con %{count} item(s)"
  }.freeze

  private

  def movement_path
    entradas_path
  end

  def movement_tipo
    :entrada
  end

  def cart_key
    :entrada_cart
  end

  def build_item
    Movimientos::StockIncreaseItemBuilder.call(params, cart_items: cart["items"])
  end

  def service_class
    Movimientos::CreateEntrada
  end

  def header_validation_error
    return "Debe ingresar el responsable de la entrada antes de confirmar." if cart["responsable"].to_s.strip.blank?
    return "Debe seleccionar un proyecto" if cart["id_proyecto"].blank?

    nil
  end

  def load_page_data
    super
    @nombres_cables = @articulos.select(&:es_cable?).map(&:nombre)
  end
end
