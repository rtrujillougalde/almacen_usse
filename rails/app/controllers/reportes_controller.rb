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

    @preview_rows = build_preview_rows
    @total_costo = @kind == "comparativo" ? @rows.sum { |r| r[:costo_material_usado].to_f } : nil
  end

  # Validates filters then redirects (303) so Turbo Drive updates the page.
  def create
    @centros = Proyecto.order(:c_c).pluck(:c_c)
    load_filters_from_params!

    unless @cc
      return redirect_to reportes_path(filter_params),
                         alert: "Debes seleccionar un Centro de Costos para generar el reporte."
    end

    unless %w[entrada salida comparativo].include?(@kind)
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

    unless @cc && %w[entrada salida comparativo].include?(@kind)
      redirect_to reportes_path, alert: "Parámetros de reporte inválidos."
      return
    end

    rows = fetch_rows
    if rows.blank?
      redirect_to reportes_path(filter_params), alert: empty_message
      return
    end

    format = params[:file_format].presence || "pdf"
    report_type = @kind == "comparativo" ? "comparativo" : @kind

    if format == "pdf"
      pdf =
        if @kind == "comparativo"
          Reportes::PdfGenerator.comparativo(cc: @cc, rows: rows)
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
        if @kind == "comparativo"
          Reportes::ExcelGenerator.comparativo(rows: rows)
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
    when "entrada", "salida"
      Reportes::Query.movement_rows(
        cc: @cc, movement_type: @kind, date_from: @date_from, date_to: @date_to
      ).to_a
    when "comparativo"
      Reportes::Query.comparativo_rows(cc: @cc, date_from: @date_from, date_to: @date_to)
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
    else
      "No se encontraron registros en el rango de fechas especificado."
    end
  end

  def build_preview_rows
    if @kind == "comparativo"
      @rows.map do |r|
        {
          "C.C" => r[:c_c],
          "Material" => r[:material],
          "Tipo" => r[:tipo],
          "Unidad" => r[:unidad_medida],
          "Precio Unit." => format("$%.2f", r[:precio_unitario].to_f),
          "Total Entradas" => r[:total_entrada],
          "Total Salidas" => r[:total_salida],
          "Usado" => r[:usado],
          "Costo material usado" => format("$%.2f", r[:costo_material_usado].to_f)
        }
      end
    else
      @rows.map do |r|
        precio = r.precio_unitario.to_f
        total = r.cantidad.to_f * precio
        {
          "Fecha/Hora" => r.fecha_hora,
          "C.C" => r.c_c,
          "Material" => r.material,
          "Cantidad" => r.cantidad,
          "Unidad" => r.unidad_medida,
          "Precio Unit." => format("$%.2f", precio),
          "Total" => format("$%.2f", total)
        }
      end
    end
  end
end
