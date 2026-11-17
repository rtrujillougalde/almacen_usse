require "rails_helper"

RSpec.describe "Documentos del trabajador", type: :request do
  before { sign_in_as(:admin) }

  let(:trabajador) { Trabajador.create!(nombre: "Ana", grupo: Grupo.create!(nombre: "A")) }

  def png_upload
    file = Tempfile.new([ "ine", ".png" ])
    file.binmode
    file.write(Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="))
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "image/png")
  end

  it "lists the document slots" do
    get trabajador_documentos_path(trabajador)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("INE")
    expect(response.body).to include("Certificado médico")
    expect(response.body).to include("Agregar")
    expect(response.body).not_to include("Descargar")
  end

  it "stores a png and offers view and download" do
    patch trabajador_documentos_path(trabajador), params: { campo: "ine", archivo: png_upload }

    expect(response).to redirect_to(trabajador_documentos_path(trabajador))
    follow_redirect!
    expect(response.body).to include("Ver")
    expect(response.body).to include("Descargar")
    expect(trabajador.reload.documento.ine).to be_attached
  end

  it "rejects a file that is not pdf or png" do
    file = Tempfile.new([ "nota", ".txt" ])
    file.write("hola")
    file.rewind
    upload = Rack::Test::UploadedFile.new(file.path, "text/plain")

    patch trabajador_documentos_path(trabajador), params: { campo: "rfc", archivo: upload }

    expect(response).to have_http_status(:unprocessable_content)
    expect(Documento.count).to eq(0)
  end
end
