class ReportesController < ApplicationController
  before_action -> { authorize_page!("reportes") }

  def index
    @centros = Proyecto.order(:c_c).pluck(:c_c)
  end

  def create
    cc = params[:c_c].presence
    unless cc
      @centros = Proyecto.order(:c_c).pluck(:c_c)
      flash.now[:alert] = "Selecciona un centro de costos."
      return render :index, status: :unprocessable_entity
    end

    date_from = params[:date_from].presence
    date_to = params[:date_to].presence
    kind = params[:kind]
    format = params[:file_format]

    data =
      case kind
      when "entrada", "salida"
        Reportes::Query.movement_rows(cc: cc, movement_type: kind, date_from: date_from, date_to: date_to)
      when "comparativo"
        Reportes::Query.comparativo_rows(cc: cc, date_from: date_from, date_to: date_to)
      else
        @centros = Proyecto.order(:c_c).pluck(:c_c)
        flash.now[:alert] = "Tipo de reporte inválido."
        return render :index, status: :unprocessable_entity
      end

    filename_base = "reporte_#{kind}_cc#{cc}_#{Time.current.strftime('%Y%m%d_%H%M')}"

    if format == "pdf"
      pdf =
        if kind == "comparativo"
          Reportes::PdfGenerator.comparativo(cc: cc, rows: data)
        else
          Reportes::PdfGenerator.movement(title: kind.capitalize, cc: cc, rows: data)
        end
      send_data pdf, filename: "#{filename_base}.pdf", type: "application/pdf", disposition: "attachment"
    else
      xlsx =
        if kind == "comparativo"
          Reportes::ExcelGenerator.comparativo(cc: cc, rows: data)
        else
          Reportes::ExcelGenerator.movement(title: kind.capitalize, cc: cc, rows: data)
        end
      send_data xlsx, filename: "#{filename_base}.xlsx",
                type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                disposition: "attachment"
    end
  end
end
