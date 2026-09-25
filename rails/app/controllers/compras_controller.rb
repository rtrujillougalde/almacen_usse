class ComprasController < MovementsController
  MESSAGES = {
    not_started: "Inicia una nueva compra primero.",
    item_added: "Item agregado a la compra.",
    cancelled: "Compra cancelada.",
    none_in_progress: "No hay una compra en curso.",
    nothing_pending: "No hay una compra pendiente de confirmación.",
    registered: "Compra registrada con %{count} item(s)"
  }.freeze

  private

  def movement_path
    compras_path
  end

  def movement_tipo
    :compra
  end

  def cart_key
    :compra_cart
  end

  def build_item
    Movimientos::CompraItemBuilder.call(params, cart_items: cart["items"])
  end

  def service_class
    Movimientos::CreateCompra
  end

  # A compra is the only movement that records who was paid and in what.
  def default_cart
    super.merge("moneda" => nil, "id_proveedor" => nil)
  end

  def sync_header_from_params!
    super
    cart["moneda"] = params[:moneda].presence
    cart["id_proveedor"] = params[:id_proveedor].presence
  end

  def service_args
    super.merge(
      moneda: cart["moneda"],
      proveedor: Proveedor.find_by(id_proveedor: cart["id_proveedor"])
    )
  end

  def header_validation_error
    return "Responsable es obligatorio" if cart["responsable"].to_s.strip.blank?
    return "Proyecto es obligatorio" if cart["id_proyecto"].blank?
    return "Moneda es obligatoria" if cart["moneda"].blank?
    return "Moneda inválida" unless Movimiento::MONEDAS.include?(cart["moneda"].to_s)
    return "Proveedor es obligatorio" if cart["id_proveedor"].blank?

    nil
  end

  def recent_includes
    super + [ :proveedor ]
  end

  def load_page_data
    super
    @proveedores = Proveedor.order(:nombre)
  end
end
