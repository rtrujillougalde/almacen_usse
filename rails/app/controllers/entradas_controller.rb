class EntradasController < ApplicationController
  include MovementCartConcern

  before_action -> { authorize_page!("entradas") }
  before_action :load_page_data, only: %i[index create add_item finalize]

  def index
  end

  def start
    open_cart!
    redirect_to entradas_path
  end

  def add_item
    unless cart["open"]
      redirect_to entradas_path, alert: "Inicia una nueva entrada primero."
      return
    end

    sync_header_from_params!
    item, error = build_entrada_item
    if error
      flash.now[:alert] = error
      render :index, status: :unprocessable_entity
      return
    end

    cart["items"] << item
    redirect_to entradas_path, notice: "Item agregado a la entrada."
  end

  def remove_item
    idx = params[:index].to_i
    cart["items"].delete_at(idx) if idx >= 0 && idx < cart["items"].size
    redirect_to entradas_path
  end

  def cancel
    reset_cart!
    redirect_to entradas_path, notice: "Entrada cancelada."
  end

  def finalize
    unless cart["open"]
      redirect_to entradas_path, alert: "No hay una entrada en curso."
      return
    end

    sync_header_from_params!

    if cart["items"].blank?
      flash.now[:alert] = "Debe agregar al menos un item"
      render :index, status: :unprocessable_entity
      return
    end

    if cart["responsable"].to_s.strip.blank?
      flash.now[:alert] = "Debe ingresar el responsable de la entrada antes de confirmar."
      render :index, status: :unprocessable_entity
      return
    end

    if cart["id_proyecto"].blank?
      flash.now[:alert] = "Debe seleccionar un proyecto"
      render :index, status: :unprocessable_entity
      return
    end

    cart["open"] = false
    cart["pending_confirmation"] = true
    redirect_to entradas_path
  end

  def dismiss_confirmation
    cart["pending_confirmation"] = false
    cart["open"] = true
    redirect_to entradas_path
  end

  def create
    unless cart["pending_confirmation"] && cart["items"].present?
      redirect_to entradas_path, alert: "No hay una entrada pendiente de confirmación."
      return
    end

    proyecto = Proyecto.find(cart["id_proyecto"])
    result = Movimientos::CreateEntrada.call(
      proyecto: proyecto,
      responsable: cart["responsable"],
      observaciones: cart["observaciones"].presence,
      items: cart_items_for_service
    )

    if result.success?
      count = cart["items"].size
      reset_cart!
      redirect_to entradas_path, notice: "Movimiento registrado con #{count} item(s)"
    else
      cart["pending_confirmation"] = false
      cart["open"] = true
      flash.now[:alert] = result.error
      render :index, status: :unprocessable_entity
    end
  end

  private

  def cart_key
    :entrada_cart
  end

  def load_page_data
    load_common_form_data!
    @articulos = Articulo.order(:nombre)
    @nombres_cables = @articulos.select(&:es_cable?).map(&:nombre)
    @recent = Movimiento.where(tipo: :entrada)
                        .includes(:proyecto, detalle_movimientos: [ :articulo, :stock_punta ])
                        .order(fecha_hora: :desc)
                        .limit(6)
  end

  def build_entrada_item
    selection = params[:id_articulo].to_s
    is_new = selection == "__new__"

    if selection.blank?
      return [ nil, "Debe seleccionar un item" ]
    end

    if is_new
      build_new_entrada_item
    else
      build_existing_entrada_item(selection)
    end
  end

  def build_new_entrada_item
    nombre = params[:nombre].to_s.strip
    es_cable = ActiveModel::Type::Boolean.new.cast(params[:es_cable])
    errors = []
    errors << "Debe ingresar un nombre para el nuevo item" if nombre.blank?
    if es_cable
      errors << "Debe ingresar el nombre de la punta/carrete/tramo" if params[:nombre_punta].to_s.strip.blank?
      errors << "La longitud del cable debe ser mayor a 0" if params[:longitud].to_f <= 0
    else
      errors << "La cantidad debe ser mayor a 0" if params[:cantidad].to_f <= 0
    end
    return [ nil, errors.join(". ") ] if errors.any?

    item = {
      "is_new" => true,
      "nombre_item" => nombre,
      "nombre" => nombre,
      "num_catalogo" => params[:num_catalogo].to_s,
      "tipo" => params[:tipo].presence || "material",
      "precio_unitario" => params[:precio_unitario],
      "unidad_medida" => params[:unidad_medida],
      "categoria" => params[:categoria],
      "stock_minimo" => params[:stock_minimo],
      "es_cable" => es_cable,
      "nombre_punta" => params[:nombre_punta].to_s,
      "longitud" => params[:longitud].to_f,
      "cantidad" => params[:cantidad].to_f,
      "color" => es_cable ? params[:color].presence : nil
    }
    [ item, nil ]
  end

  def build_existing_entrada_item(id)
    articulo = Articulo.find_by(id_articulo: id)
    return [ nil, "Artículo no encontrado" ] unless articulo

    if articulo.es_cable?
      errors = []
      errors << "Debe ingresar el nombre de la punta/carrete/tramo" if params[:nombre_punta].to_s.strip.blank?
      errors << "La longitud del cable debe ser mayor a 0" if params[:longitud].to_f <= 0
      return [ nil, errors.join(". ") ] if errors.any?

      item = {
        "is_new" => false,
        "id_articulo" => articulo.id_articulo,
        "nombre_item" => articulo.nombre,
        "es_cable" => true,
        "nombre_punta" => params[:nombre_punta].to_s,
        "longitud" => params[:longitud].to_f,
        "cantidad" => 0,
        "color" => params[:color].presence
      }
    else
      return [ nil, "La cantidad debe ser mayor a 0" ] if params[:cantidad].to_f <= 0

      item = {
        "is_new" => false,
        "id_articulo" => articulo.id_articulo,
        "nombre_item" => articulo.nombre,
        "es_cable" => false,
        "cantidad" => params[:cantidad].to_f,
        "nombre_punta" => "",
        "longitud" => 0,
        "color" => nil
      }
    end
    [ item, nil ]
  end

  def cart_items_for_service
    cart["items"].map do |item|
      {
        is_new: item["is_new"],
        id_articulo: item["id_articulo"],
        nombre: item["nombre"] || item["nombre_item"],
        num_catalogo: item["num_catalogo"],
        tipo: item["tipo"],
        precio_unitario: item["precio_unitario"],
        unidad_medida: item["unidad_medida"],
        categoria: item["categoria"],
        stock_minimo: item["stock_minimo"],
        es_cable: item["es_cable"],
        nombre_punta: item["nombre_punta"],
        longitud: item["longitud"],
        cantidad: item["cantidad"],
        color: item["color"]
      }
    end
  end
end
