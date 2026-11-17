class DocumentosController < ApplicationController
  layout "personal"

  before_action -> { require_system!(:personal) }
  before_action :set_trabajador

  def show
    @documento = @trabajador.documento || @trabajador.build_documento
  end

  def update
    @documento = @trabajador.documento || @trabajador.build_documento
    field = params[:campo].to_s
    unless Documento::FILE_FIELDS.map(&:to_s).include?(field)
      return redirect_to trabajador_documentos_path(@trabajador), alert: "Documento inválido."
    end

    file = params[:archivo]
    if file.blank?
      return redirect_to trabajador_documentos_path(@trabajador), alert: "Selecciona un archivo PDF o PNG."
    end

    @documento.public_send(field).attach(file)
    if @documento.save
      redirect_to trabajador_documentos_path(@trabajador), notice: "#{Documento::LABELS[field]} guardado."
    else
      render :show, status: :unprocessable_content
    end
  end

  private

  def set_trabajador
    @trabajador = Trabajador.find(params[:trabajador_id])
  end
end
