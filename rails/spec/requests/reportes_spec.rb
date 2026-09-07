require "rails_helper"

RSpec.describe "Reportes generate flow", type: :request do
  let!(:proyecto) { create(:proyecto, c_c: 9999) }
  let!(:articulo) { create(:articulo, nombre: "Reporte Item", precio_unitario: 5, unidad_medida: "pza") }

  before do
    entrada = create(:movimiento, proyecto: proyecto, tipo: :entrada, fecha_hora: Time.zone.parse("2026-03-15 10:00"))
    create(:detalle_movimiento, movimiento: entrada, articulo: articulo, cantidad: 2)

    salida = create(:movimiento, proyecto: proyecto, tipo: :salida, fecha_hora: Time.zone.parse("2026-03-20 12:00"))
    create(:detalle_movimiento, movimiento: salida, articulo: articulo, cantidad: 1)
  end

  describe "POST /reportes (Generar Reporte)" do
    it "redirects with 303 see_other and generated=1 for entradas (Turbo PRG)" do
      sign_in_as(:admin)

      post reportes_path, params: { c_c: 9999, kind: "entrada" }

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(reportes_path(c_c: "9999", kind: "entrada", generated: "1"))
    end

    it "shows preview and both download links after following the redirect" do
      sign_in_as(:admin)

      post reportes_path, params: { c_c: 9999, kind: "entrada" }
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Se encontraron 1 registros de entrada")
      expect(response.body).to include("Vista previa de datos")
      expect(response.body).to include("Descargar PDF")
      expect(response.body).to include("Descargar Excel")
      expect(response.body).to include("Reporte Item")
      expect(response.body).not_to include("Precio Unit.")
      expect(response.body).not_to include(">Total<")
      expect(response.body).to include("Descargar PDF")
      expect(response.body).to include("Descargar Excel")
      expect(response.body).to include("/reportes/download?")
      expect(response.body).to include("file_format=pdf")
      expect(response.body).to include("file_format=xlsx")
      expect(response.body).to include("kind=entrada")
      expect(response.body).to include("c_c=9999")
    end

    it "generates salidas preview" do
      sign_in_as(:admin)

      post reportes_path, params: { c_c: 9999, kind: "salida" }
      expect(response).to redirect_to(reportes_path(c_c: "9999", kind: "salida", generated: "1"))
      follow_redirect!

      expect(response.body).to include("Se encontraron 1 registros de salida")
      expect(response.body).to include("Reporte Item")
      expect(response.body).to include("Generar Reporte de Salidas")
    end

    it "generates compras preview with proveedor and moneda" do
      sign_in_as(:admin)
      proveedor = create(:proveedor, nombre: "Aceros Norte")
      compra = create(:movimiento, :compra, proyecto: proyecto, proveedor: proveedor, moneda: "MXN")
      create(:detalle_movimiento, movimiento: compra, articulo: articulo, cantidad: 3, precio_unitario: 11)

      post reportes_path, params: { c_c: 9999, kind: "compra" }
      expect(response).to redirect_to(reportes_path(c_c: "9999", kind: "compra", generated: "1"))
      follow_redirect!

      expect(response.body).to include("Se encontraron 1 registros de compra")
      expect(response.body).to include("Reporte Item")
      expect(response.body).to include("Aceros Norte")
      expect(response.body).to include("MXN")
      expect(response.body).to include("Proveedor")
      expect(response.body).to include("Moneda")
      expect(response.body).to include("Precio Unit.")
      expect(response.body).to include("$11.00")
      expect(response.body).to include("Generar Reporte de Compras")
    end

    it "generates material utilizado preview with costo total metric" do
      sign_in_as(:admin)
      compra = create(:movimiento, :compra, proyecto: proyecto)
      create(:detalle_movimiento, movimiento: compra, articulo: articulo, cantidad: 4, precio_unitario: 11)

      post reportes_path, params: { c_c: 9999, kind: "utilizado" }
      follow_redirect!

      expect(response.body).to include("Se encontraron 1 materiales/herramientas")
      expect(response.body).to include("Costo Total")
      expect(response.body).to include("MXN")
      expect(response.body).to include("Reporte Item")
      expect(response.body).to include("Compras")
      expect(response.body).to include("Utilizado")
      expect(response.body).to include("Generar Reporte de Material Utilizado")
      expect(response.body).not_to include("Comparativo")
    end

    it "shows a separate preview table per moneda" do
      sign_in_as(:admin)
      mxn = create(:movimiento, :compra, proyecto: proyecto, moneda: "MXN")
      create(:detalle_movimiento, movimiento: mxn, articulo: articulo, cantidad: 4, precio_unitario: 11)
      usd = create(:movimiento, :compra, proyecto: proyecto, moneda: "USD")
      create(:detalle_movimiento, movimiento: usd, articulo: articulo, cantidad: 6, precio_unitario: 11)

      post reportes_path, params: { c_c: 9999, kind: "utilizado" }
      follow_redirect!

      expect(response.body).to include("Moneda: MXN")
      expect(response.body).to include("Moneda: USD")
      expect(response.body).to include("Costo Total (MXN)")
      expect(response.body).to include("Costo Total (USD)")
    end

    it "allows consulta to generate reports" do
      sign_in_as(:consulta)

      post reportes_path, params: { c_c: 9999, kind: "entrada" }
      expect(response).to have_http_status(:see_other)
      follow_redirect!
      expect(response.body).to include("Vista previa de datos")
    end

    it "redirects with alert when centro de costos is missing" do
      sign_in_as(:admin)

      post reportes_path, params: { kind: "entrada" }

      expect(response).to redirect_to(reportes_path(kind: "entrada"))
      follow_redirect!
      expect(response.body).to include("Debes seleccionar un Centro de Costos")
      expect(response.body).not_to include("Vista previa de datos")
    end

    it "redirects with alert when kind is invalid" do
      sign_in_as(:admin)

      post reportes_path, params: { c_c: 9999, kind: "inventario" }

      expect(response).to redirect_to(reportes_path(c_c: "9999", kind: "inventario"))
      follow_redirect!
      expect(response.body).to include("Tipo de reporte inválido")
    end

    it "redirects with alert when there is no matching data" do
      sign_in_as(:admin)

      post reportes_path, params: { c_c: 9999, kind: "entrada", filter_dates: "1",
                                   date_from: "2020-01-01", date_to: "2020-01-31" }

      expect(response).to redirect_to(
        reportes_path(
          c_c: "9999", kind: "entrada", filter_dates: "1",
          date_from: "2020-01-01", date_to: "2020-01-31"
        )
      )
      follow_redirect!
      expect(response.body).to include("No se encontraron registros de entrada")
      expect(response.body).not_to include("Vista previa de datos")
    end

    it "respects optional date range when generating" do
      sign_in_as(:admin)

      post reportes_path, params: {
        c_c: 9999, kind: "entrada", filter_dates: "1",
        date_from: "2026-03-01", date_to: "2026-03-31"
      }
      follow_redirect!

      expect(response.body).to include("Vista previa de datos")
      expect(response.body).to include("Reporte Item")
    end

    it "does not show preview on index without generated=1" do
      sign_in_as(:admin)

      get reportes_path, params: { c_c: 9999, kind: "entrada" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Generar Reporte de Entradas")
      expect(response.body).not_to include("Vista previa de datos")
    end
  end

  describe "full flow: generate then download files" do
    it "downloads PDF and Excel using the same filters from the generated preview" do
      sign_in_as(:admin)

      post reportes_path, params: { c_c: 9999, kind: "entrada" }
      follow_redirect!
      expect(response.body).to include("Descargar PDF")

      get download_reportes_path, params: { c_c: 9999, kind: "entrada", file_format: "pdf" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to start_with("%PDF")
      expect(pdf_text(response.body)).to include("Reporte Item")

      get download_reportes_path, params: { c_c: 9999, kind: "entrada", file_format: "xlsx" }
      expect(response).to have_http_status(:ok)
      expect(response.body[0, 2]).to eq("PK")
      expect(xlsx_rows(response.body)[1][2]).to eq("Reporte Item")
    end

    it "downloads material utilizado files after generate" do
      sign_in_as(:consulta)

      post reportes_path, params: { c_c: 9999, kind: "utilizado" }
      follow_redirect!

      get download_reportes_path, params: { c_c: 9999, kind: "utilizado", file_format: "pdf" }
      expect(response.body).to start_with("%PDF")
      expect(pdf_text(response.body)).to include("Reporte de Material Utilizado")

      get download_reportes_path, params: { c_c: 9999, kind: "utilizado", file_format: "xlsx" }
      expect(xlsx_sheet_names(response.body)).to eq([ "MXN" ])
    end
  end
end

RSpec.describe "Reportes downloads", type: :request do
  let!(:proyecto) { create(:proyecto, c_c: 9999) }
  let!(:articulo) { create(:articulo, nombre: "Reporte Item", precio_unitario: 5, unidad_medida: "pza") }

  before do
    entrada = create(:movimiento, proyecto: proyecto, tipo: :entrada)
    create(:detalle_movimiento, movimiento: entrada, articulo: articulo, cantidad: 2)

    salida = create(:movimiento, proyecto: proyecto, tipo: :salida)
    create(:detalle_movimiento, movimiento: salida, articulo: articulo, cantidad: 1)
  end

  describe "PDF download" do
    it "returns a real PDF for entradas with expected content" do
      sign_in_as(:admin)

      get download_reportes_path, params: { c_c: 9999, kind: "entrada", file_format: "pdf" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to include("reporte_entrada_cc_9999.pdf")
      expect(response.body).to start_with("%PDF")
      expect(response.body).to include("%%EOF")

      text = pdf_text(response.body)
      expect(text).to include("Reporte de Entradas de Almacén")
      expect(text).to include("Reporte Item")
      expect(text).not_to include("Precio Unit.")
      expect(text).not_to include("TOTAL GENERAL")
      expect(text).not_to match(/(^|\s)Total(\s|$)/)
    end

    it "returns a real PDF for salidas" do
      sign_in_as(:admin)

      get download_reportes_path, params: { c_c: 9999, kind: "salida", file_format: "pdf" }

      expect(response.body).to start_with("%PDF")
      expect(pdf_text(response.body)).to include("Reporte de Salidas de Almacén")
    end

    it "returns a real PDF for compras with proveedor and moneda" do
      sign_in_as(:admin)
      proveedor = create(:proveedor, nombre: "Aceros Norte")
      compra = create(:movimiento, :compra, proyecto: proyecto, proveedor: proveedor, moneda: "USD")
      create(:detalle_movimiento, movimiento: compra, articulo: articulo, cantidad: 3, precio_unitario: 11)

      get download_reportes_path, params: { c_c: 9999, kind: "compra", file_format: "pdf" }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Disposition"]).to include("reporte_compra_cc_9999.pdf")
      text = pdf_text(response.body)
      expect(text).to include("Reporte de Compras de Almacén")
      expect(text).to include("Reporte Item")
      expect(text).to include("Aceros Norte")
      expect(text).to include("USD")
      expect(text).to include("Precio") # "Precio Unit." wraps in PDF layout
      expect(text).to include("Unit.")
      expect(text).to include("$11.00")
    end

    it "returns a real PDF for material utilizado" do
      sign_in_as(:admin)

      get download_reportes_path, params: { c_c: 9999, kind: "utilizado", file_format: "pdf" }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Disposition"]).to include("reporte_utilizado_cc_9999.pdf")
      expect(response.body).to start_with("%PDF")

      text = pdf_text(response.body)
      expect(text).to include("Reporte de Material Utilizado")
      expect(text).to include("Reporte Item")
      expect(text).to include("Moneda: MXN")
      expect(text).to include("Costo Total")
    end
  end

  describe "Excel download" do
    it "returns a real XLSX for entradas with expected rows" do
      sign_in_as(:consulta)

      get download_reportes_path, params: { c_c: 9999, kind: "entrada", file_format: "xlsx" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
      expect(response.headers["Content-Disposition"]).to include("reporte_entrada_cc_9999.xlsx")
      expect(response.body[0, 2]).to eq("PK")

      expect(xlsx_sheet_names(response.body)).to eq([ "Entradas" ])
      rows = xlsx_rows(response.body)
      expect(rows.first).to eq(
        [ "Fecha/Hora", "C.C", "Material", "Cantidad", "Unidad" ]
      )
      expect(rows.first).not_to include("Precio Unit.", "Total")
      expect(rows[1][2]).to eq("Reporte Item")
      expect(rows[1][3].to_f).to eq(2.0)
      expect(rows[1].length).to eq(5)
    end

    it "returns a real XLSX for compras with proveedor and moneda" do
      sign_in_as(:admin)
      proveedor = create(:proveedor, nombre: "Aceros Norte")
      compra = create(:movimiento, :compra, proyecto: proyecto, proveedor: proveedor, moneda: "MXN")
      create(:detalle_movimiento, movimiento: compra, articulo: articulo, cantidad: 3, precio_unitario: 11)

      get download_reportes_path, params: { c_c: 9999, kind: "compra", file_format: "xlsx" }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Disposition"]).to include("reporte_compra_cc_9999.xlsx")
      expect(xlsx_sheet_names(response.body)).to eq([ "Compras" ])
      rows = xlsx_rows(response.body)
      expect(rows.first).to eq(
        [ "Fecha/Hora", "C.C", "Material", "Cantidad", "Unidad", "Precio Unit.", "Proveedor", "Moneda" ]
      )
      expect(rows[1][2]).to eq("Reporte Item")
      expect(rows[1][5].to_f).to eq(11.0)
      expect(rows[1][6]).to eq("Aceros Norte")
      expect(rows[1][7]).to eq("MXN")
    end

    it "returns a real XLSX for material utilizado with expected columns" do
      sign_in_as(:admin)

      get download_reportes_path, params: { c_c: 9999, kind: "utilizado", file_format: "xlsx" }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Disposition"]).to include("reporte_utilizado_cc_9999.xlsx")
      expect(response.body[0, 2]).to eq("PK")
      expect(xlsx_sheet_names(response.body)).to eq([ "MXN" ])

      rows = xlsx_rows(response.body, sheet: "MXN")
      expect(rows.first).to eq(
        [
          "C.C", "Material", "Tipo", "Unidad", "Precio Unit.",
          "Compras", "Salidas", "Entradas", "Utilizado", "Costo"
        ]
      )
      expect(rows[1][1]).to eq("Reporte Item")
      expect(rows[1][5].to_f).to eq(0.0)
      expect(rows[1][6].to_f).to eq(1.0)
      expect(rows[1][7].to_f).to eq(2.0)
      expect(rows[1][8].to_f).to eq(-1.0)
    end
  end
end

RSpec.describe "Reportes access", type: :request do
  let!(:proyecto) { create(:proyecto, c_c: 9999) }

  it "forbids operador from reportes" do
    sign_in_as(:operador)
    get reportes_path
    expect(response).to redirect_to(inventario_path)
  end

  it "forbids operador from generating reports" do
    sign_in_as(:operador)
    post reportes_path, params: { c_c: 9999, kind: "entrada" }
    expect(response).to redirect_to(inventario_path)
  end

  it "allows admin to open the reportes form" do
    sign_in_as(:admin)
    get reportes_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Selecciona el tipo de reporte")
    expect(response.body).to include("Centro de Costos")
  end
end
