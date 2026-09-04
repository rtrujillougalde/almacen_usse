require "rails_helper"

RSpec.describe "Reportes", type: :request do
  let!(:proyecto) { create(:proyecto, c_c: 9999) }
  let!(:articulo) { create(:articulo, nombre: "Reporte Item", precio_unitario: 5) }

  before do
    mov = create(:movimiento, proyecto: proyecto, tipo: :entrada)
    create(:detalle_movimiento, movimiento: mov, articulo: articulo, cantidad: 2)
  end

  it "downloads PDF for admin" do
    sign_in_as(:admin)
    post reportes_path, params: { c_c: 9999, kind: "entrada", file_format: "pdf" }
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/pdf")
    expect(response.headers["Content-Disposition"]).to include("attachment")
  end

  it "downloads Excel for consulta" do
    sign_in_as(:consulta)
    post reportes_path, params: { c_c: 9999, kind: "entrada", file_format: "xlsx" }
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
  end

  it "forbids operador from reportes" do
    sign_in_as(:operador)
    get reportes_path
    expect(response).to redirect_to(inventario_path)
  end

  it "requires centro de costos" do
    sign_in_as(:admin)
    post reportes_path, params: { kind: "entrada", file_format: "pdf" }
    expect(response).to have_http_status(:unprocessable_entity)
  end
end
