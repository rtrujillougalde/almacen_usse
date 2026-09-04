class ArticulosController < ApplicationController
  before_action -> { authorize_page!("inventario") }
  before_action :set_articulo

  def edit
    @proveedores = Proveedor.order(:nombre)
    @available_puntas = @articulo.stock_puntas.merge(StockPunta.available).order(:id_punta)
  end

  def update
    @proveedores = Proveedor.order(:nombre)
    @available_puntas = @articulo.stock_puntas.merge(StockPunta.available).order(:id_punta)

    stock_changed = stock_fields_changed?
    puntas_attrs = punta_params_list
    longitud_changed = puntas_length_changed?(puntas_attrs)

    if (stock_changed || longitud_changed) && !admin_password_valid?
      flash.now[:alert] = "Se requiere la contraseña de admin para cambiar stock o longitudes."
      return render :edit, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      @articulo.assign_attributes(articulo_params)
      if @articulo.es_cable?
        apply_puntas!(puntas_attrs)
        @articulo.cantidad_en_stock = @articulo.stock_puntas.merge(StockPunta.available).sum(:longitud)
      end
      @articulo.save!
    end

    redirect_to inventario_path, notice: "Artículo actualizado."
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.record.errors.full_messages.to_sentence
    render :edit, status: :unprocessable_entity
  end

  private

  def set_articulo
    @articulo = Articulo.find(params[:id])
  end

  def articulo_params
    params.require(:articulo).permit(
      :nombre, :num_catalogo, :cantidad_en_stock, :unidad_medida, :stock_minimo,
      :tipo, :categoria, :es_cable, :almacen, :ubicacion, :proveedor, :precio_unitario
    )
  end

  def punta_params_list
    raw = params.dig(:articulo, :puntas)
    return [] if raw.blank?

    values = raw.respond_to?(:values) ? raw.values : Array(raw)
    values.map do |p|
      p.permit(:id_punta, :nombre_punta, :longitud, :color)
    end
  end

  def stock_fields_changed?
    new_stock = params.dig(:articulo, :cantidad_en_stock)
    return false if new_stock.blank?
    new_stock.to_f != @articulo.cantidad_en_stock.to_f
  end

  def puntas_length_changed?(puntas_attrs)
    puntas_attrs.any? do |attrs|
      next false if attrs[:id_punta].blank?
      punta = @articulo.stock_puntas.find_by(id_punta: attrs[:id_punta])
      next false unless punta
      attrs[:longitud].to_f != punta.longitud.to_f
    end
  end

  def admin_password_valid?
    password = params[:admin_password].to_s
    admin = User.find_by(username: "admin")
    admin&.valid_password?(password)
  end

  def apply_puntas!(puntas_attrs)
    puntas_attrs.each do |attrs|
      next if attrs[:id_punta].blank?
      punta = @articulo.stock_puntas.find(attrs[:id_punta])
      punta.update!(
        nombre_punta: attrs[:nombre_punta],
        longitud: attrs[:longitud],
        color: attrs[:color]
      )
    end
  end
end
