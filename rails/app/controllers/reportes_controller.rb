class ReportesController < ApplicationController
  before_action -> { authorize_page!("reportes") }

  helper_method :filter_params

  def index
    @centros = Proyecto.order(:c_c).pluck(:c_c)
    load_filters_from_params!

    # After Generar (PRG), show preview + download buttons on this same page
    # like Streamlit p_reportes.py.
    return unless generated_requested?

    @rows = fetch_rows
    if @rows.blank?
      flash.now[:alert] = empty_message
      return
    end

    if @kind == "utilizado"
      @preview_groups = build_preview_groups
    else
      @preview_rows = build_preview_rows
    end
  end

  # Validates filters then redirects (303) so Turbo Drive updates the page.
  def create
    @centros = Proyecto.order(:c_c).pluck(:c_c)
    load_filters_from_params!

    unless @cc
      return redirect_to reportes_path(filter_params),
                         alert: "Debes seleccionar un Centro de Costos para generar el reporte."
    end

    unless %w[entrada salida compra utilizado].include?(@kind)
      return redirect_to reportes_path(filter_params), alert: "Tipo de reporte inválido."
    end

    rows = fetch_rows
    if rows.blank?
      return redirect_to reportes_path(filter_params), alert: empty_message
    end

    redirect_to reportes_path(filter_params.merge(generated: "1")), status: :see_other
  end

  def download
    load_filters_from_params!

    unless @cc && %w[entrada salida compra utilizado].include?(@kind)
      redirect_to reportes_path, alert: "Parámetros de reporte inválidos."
      return
    end

    rows = fetch_rows
    if rows.blank?
      redirect_to reportes_path(filter_params), alert: empty_message
      return
    end

    format = params[:file_format].presence || "pdf"
    report_type = @kind

    if format == "pdf"
      pdf =
        if @kind == "utilizado"
          Reportes::PdfGenerator.utilizado(cc: @cc, groups: rows)
        else
          Reportes::PdfGenerator.movement(movement_type: @kind, cc: @cc, rows: rows)
        end
      send_data pdf,
                filename: Reportes::Filename.build(
                  report_type: report_type, date_from: @date_from, date_to: @date_to, cc: @cc, extension: "pdf"
                ),
                type: "application/pdf",
                disposition: "attachment"
    else
      xlsx =
        if @kind == "utilizado"
          Reportes::ExcelGenerator.utilizado(groups: rows)
        else
          Reportes::ExcelGenerator.movement(movement_type: @kind, rows: rows)
        end
      send_data xlsx,
                filename: Reportes::Filename.build(
                  report_type: report_type, date_from: @date_from, date_to: @date_to, cc: @cc, extension: "xlsx"
                ),
                type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                disposition: "attachment"
    end
  end

  private

  def generated_requested?
    ActiveModel::Type::Boolean.new.cast(params[:generated])
  end

  def filter_params
    {
      c_c: @cc,
      kind: @kind,
      filter_dates: @filter_dates ? "1" : nil,
      date_from: @date_from,
      date_to: @date_to
    }.compact
  end

  def load_filters_from_params!
    @cc = params[:c_c].presence
    @kind = params[:kind].presence || "entrada"
    @filter_dates = ActiveModel::Type::Boolean.new.cast(params[:filter_dates])
    if @filter_dates
      @date_from = params[:date_from].presence
      @date_to = params[:date_to].presence
    else
      @date_from = nil
      @date_to = nil
    end
  end

  def fetch_rows
    case @kind
    when "entrada", "salida", "compra"
      Reportes::Query.movement_rows(
        cc: @cc, movement_type: @kind, date_from: @date_from, date_to: @date_to
      ).to_a
    when "utilizado"
      Reportes::Query.utilizado_groups(cc: @cc, date_from: @date_from, date_to: @date_to)
    else
      []
    end
  end

  def empty_message
    case @kind
    when "entrada"
      "No se encontraron registros de entrada en el rango de fechas especificado."
    when "salida"
      "No se encontraron registros de salida en el rango de fechas especificado."
    when "compra"
      "No se encontraron registros de compra en el rango de fechas especificado."
    when "utilizado"
      "No se encontraron movimientos para calcular el material utilizado."
    else
      "No se encontraron registros en el rango de fechas especificado."
    end
  end

  def build_preview_groups
    @rows.map do |group|
      {
        moneda: group[:moneda],
        total_costo: group[:total_costo],
        rows: group[:rows].map { |r| preview_utilizado_row(r) }
      }
    end
  end

  def preview_utilizado_row(r)
    {
      "C.C" => r[:c_c],
      "Material" => r[:material],
      "Tipo" => r[:tipo],
      "Unidad" => r[:unidad_medida],
      "Precio Unit." => format("$%.2f", r[:precio_unitario].to_f),
      "Compras" => r[:total_compra],
      "Salidas" => r[:total_salida],
      "Entradas" => r[:total_entrada],
      "Utilizado" => r[:utilizado],
      "Costo" => format("$%.2f", r[:costo].to_f)
    }
  end

  def build_preview_rows
    @rows.map do |r|
      preview = {
        "Fecha/Hora" => r.fecha_hora,
        "C.C" => r.c_c,
        "Material" => r.material,
        "Cantidad" => r.cantidad,
        "Unidad" => r.unidad_medida
      }
      if @kind == "compra"
        preview["Precio Unit."] = format("$%.2f", r.precio_unitario.to_f)
        preview["Proveedor"] = r.proveedor
        preview["Moneda"] = r.moneda
      end
      preview
    end
  end
end
