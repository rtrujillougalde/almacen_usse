require "rails_helper"

RSpec.describe Reportes::PdfGenerator do
  let(:proyecto) { create(:proyecto, c_c: 111) }
  let(:articulo) do
    create(:articulo, nombre: "Cable X", precio_unitario: 10, unidad_medida: "m")
  end

  def add_movement(tipo:, cantidad:)
    mov = create(:movimiento, proyecto: proyecto, tipo: tipo)
    create(:detalle_movimiento, movimiento: mov, articulo: articulo, cantidad: cantidad)
  end

  describe ".movement" do
    it "creates a valid PDF with title and row data without Precio Unit. or Total" do
      add_movement(tipo: :entrada, cantidad: 3)
      rows = Reportes::Query.movement_rows(cc: 111, movement_type: "entrada").to_a

      pdf = described_class.movement(movement_type: "entrada", cc: 111, rows: rows)

      expect(pdf).to start_with("%PDF")
      expect(pdf).to include("%%EOF")
      expect(pdf.bytesize).to be > 1_000

      text = pdf_text(pdf)
      expect(text).to include("Reporte de Entradas de Almacén")
      expect(text).to include("Fecha")
      expect(text).to include("Hora")
      expect(text).to include("C.C")
      expect(text).to include("111")
      expect(text).to include("Fecha/Hora")
      expect(text).to include("Material")
      expect(text).to include("Cantidad")
      expect(text).to include("Unidad")
      expect(text).to include("Cable X")
      expect(text).to include("3")
      expect(text).to include("m")
      expect(text).not_to include("Precio Unit.")
      expect(text).not_to include("TOTAL GENERAL")
      expect(text).not_to match(/(^|\s)Total(\s|$)/)
    end

    it "creates a salidas PDF with the matching title and without price columns" do
      add_movement(tipo: :salida, cantidad: 2)
      rows = Reportes::Query.movement_rows(cc: 111, movement_type: "salida").to_a

      pdf = described_class.movement(movement_type: "salida", cc: 111, rows: rows)
      text = pdf_text(pdf)

      expect(pdf).to start_with("%PDF")
      expect(text).to include("Reporte de Salidas de Almacén")
      expect(text).to include("Cable X")
      expect(text).not_to include("Precio Unit.")
      expect(text).not_to include("TOTAL GENERAL")
    end

    it "creates a compras PDF with proveedor and moneda" do
      proveedor = create(:proveedor, nombre: "Aceros Norte")
      mov = create(:movimiento, :compra, proyecto: proyecto, proveedor: proveedor, moneda: "MXN")
      create(:detalle_movimiento, movimiento: mov, articulo: articulo, cantidad: 4, precio_unitario: 9)
      rows = Reportes::Query.movement_rows(cc: 111, movement_type: "compra").to_a

      pdf = described_class.movement(movement_type: "compra", cc: 111, rows: rows)
      text = pdf_text(pdf)

      expect(pdf).to start_with("%PDF")
      expect(text).to include("Reporte de Compras de Almacén")
      expect(text).to include("Cable X")
      expect(text).to include("Proveedor")
      expect(text).to include("Moneda")
      expect(text).to include("Precio") # "Precio Unit." wraps in PDF layout
      expect(text).to include("Unit.")
      expect(text).to include("Aceros Norte")
      expect(text).to include("MXN")
      expect(text).to include("$9.00")
    end
  end

  describe ".utilizado" do
    it "creates a valid PDF with utilizado columns and costo total" do
      groups = [ {
        moneda: "MXN",
        total_costo: 70,
        rows: [ {
          c_c: 111,
          material: "Cemento",
          tipo: "material",
          unidad_medida: "pza",
          precio_unitario: 10,
          total_compra: 4,
          total_salida: 8,
          total_entrada: 5,
          utilizado: 7,
          costo: 70
        } ]
      } ]

      pdf = described_class.utilizado(cc: 111, groups: groups)
      text = pdf_text(pdf)

      expect(pdf).to start_with("%PDF")
      expect(pdf).to include("%%EOF")
      expect(text).to include("Reporte de Material Utilizado")
      expect(text).to include("MXN")
      expect(text).to include("Compras")
      expect(text).to include("Salidas")
      expect(text).to include("Entradas")
      expect(text).to include("Utilizado")
      expect(text).to include("Cemento")
      expect(text).to include("pza")
      expect(text).to include("$10.00")
      expect(text).to include("Costo Total")
      expect(text).to include("$70.00")
    end

    it "renders a separate table and costo total per moneda" do
      groups = [
        {
          moneda: "MXN",
          total_costo: 30,
          rows: [ {
            c_c: 111, material: "Cemento", tipo: "material", unidad_medida: "pza",
            precio_unitario: 10, total_compra: 3, total_salida: 0, total_entrada: 0,
            utilizado: 3, costo: 30
          } ]
        },
        {
          moneda: "USD",
          total_costo: 60,
          rows: [ {
            c_c: 111, material: "Cemento", tipo: "material", unidad_medida: "pza",
            precio_unitario: 10, total_compra: 6, total_salida: 0, total_entrada: 0,
            utilizado: 6, costo: 60
          } ]
        }
      ]

      text = pdf_text(described_class.utilizado(cc: 111, groups: groups))
      expect(text).to include("MXN")
      expect(text).to include("USD")
      expect(text).to include("$30.00")
      expect(text).to include("$60.00")
      expect(text).not_to include("$90.00")
    end
  end
end

RSpec.describe Reportes::ExcelGenerator do
  let(:proyecto) { create(:proyecto, c_c: 222) }
  let(:articulo) do
    create(:articulo, nombre: "Pintura Azul", precio_unitario: 4.5, unidad_medida: "lt")
  end

  describe ".movement" do
    it "creates an XLSX with Entradas sheet without Precio Unit. or Total" do
      mov = create(:movimiento, proyecto: proyecto, tipo: :entrada)
      create(:detalle_movimiento, movimiento: mov, articulo: articulo, cantidad: 2)
      rows = Reportes::Query.movement_rows(cc: 222, movement_type: "entrada").to_a

      xlsx = described_class.movement(movement_type: "entrada", rows: rows)

      expect(xlsx[0, 2]).to eq("PK")
      expect(xlsx.bytesize).to be > 1_000
      expect(xlsx_sheet_names(xlsx)).to eq([ "Entradas" ])

      table = xlsx_rows(xlsx)
      expect(table.first).to eq(
        [ "Fecha/Hora", "C.C", "Material", "Cantidad", "Unidad" ]
      )
      expect(table.first).not_to include("Precio Unit.", "Total")

      data_row = table[1]
      expect(data_row[1]).to eq("222")
      expect(data_row[2]).to eq("Pintura Azul")
      expect(data_row[3].to_f).to eq(2.0)
      expect(data_row[4]).to eq("lt")
      expect(data_row.length).to eq(5)
      expect(table.length).to eq(2)
    end

    it "creates a Salidas sheet for salida reports without price columns" do
      mov = create(:movimiento, proyecto: proyecto, tipo: :salida)
      create(:detalle_movimiento, movimiento: mov, articulo: articulo, cantidad: 1)
      rows = Reportes::Query.movement_rows(cc: 222, movement_type: "salida").to_a

      xlsx = described_class.movement(movement_type: "salida", rows: rows)

      expect(xlsx_sheet_names(xlsx)).to eq([ "Salidas" ])
      headers = xlsx_rows(xlsx).first
      expect(headers).to include("Material", "Cantidad", "Unidad")
      expect(headers).not_to include("Precio Unit.", "Total")
    end

    it "creates a Compras sheet with proveedor and moneda" do
      proveedor = create(:proveedor, nombre: "Aceros Norte")
      mov = create(:movimiento, :compra, proyecto: proyecto, proveedor: proveedor, moneda: "USD")
      create(:detalle_movimiento, movimiento: mov, articulo: articulo, cantidad: 2, precio_unitario: 8)
      rows = Reportes::Query.movement_rows(cc: 222, movement_type: "compra").to_a

      xlsx = described_class.movement(movement_type: "compra", rows: rows)
      table = xlsx_rows(xlsx)

      expect(xlsx_sheet_names(xlsx)).to eq([ "Compras" ])
      expect(table.first).to eq(
        [ "Fecha/Hora", "C.C", "Material", "Cantidad", "Unidad", "Precio Unit.", "Proveedor", "Moneda" ]
      )
      expect(table[1][2]).to eq("Pintura Azul")
      expect(table[1][5].to_f).to eq(8.0)
      expect(table[1][6]).to eq("Aceros Norte")
      expect(table[1][7]).to eq("USD")
    end
  end

  describe ".utilizado" do
    it "creates an XLSX sheet per moneda with expected columns" do
      groups = [
        {
          moneda: "MXN",
          total_costo: -22.5,
          rows: [ {
            c_c: 222,
            material: "Pintura Azul",
            tipo: "material",
            unidad_medida: "lt",
            precio_unitario: 4.5,
            total_compra: 2,
            total_salida: 3,
            total_entrada: 10,
            utilizado: -5,
            costo: -22.5
          } ]
        },
        {
          moneda: "USD",
          total_costo: 8,
          rows: [ {
            c_c: 222,
            material: "Pintura Azul",
            tipo: "material",
            unidad_medida: "lt",
            precio_unitario: 4,
            total_compra: 2,
            total_salida: 0,
            total_entrada: 0,
            utilizado: 2,
            costo: 8
          } ]
        }
      ]

      xlsx = described_class.utilizado(groups: groups)

      expect(xlsx[0, 2]).to eq("PK")
      expect(xlsx_sheet_names(xlsx)).to eq([ "MXN", "USD" ])

      table = xlsx_rows(xlsx, sheet: "MXN")
      expect(table.first).to eq(
        [
          "C.C", "Material", "Tipo", "Unidad", "Precio Unit.",
          "Compras", "Salidas", "Entradas", "Utilizado", "Costo"
        ]
      )
      expect(table[1][0]).to eq("222")
      expect(table[1][1]).to eq("Pintura Azul")
      expect(table[1][5].to_f).to eq(2.0)
      expect(table[1][6].to_f).to eq(3.0)
      expect(table[1][7].to_f).to eq(10.0)
      expect(table[1][8].to_f).to eq(-5.0)
      expect(table[1][9].to_f).to eq(-22.5)
    end
  end
end

RSpec.describe Reportes::Filename do
  it "matches Python naming without dates" do
    expect(described_class.build(report_type: "entrada", cc: 10, extension: "pdf"))
      .to eq("reporte_entrada_cc_10.pdf")
  end

  it "includes date range when present" do
    expect(
      described_class.build(
        report_type: "utilizado",
        date_from: "2026-01-01",
        date_to: "2026-09-04",
        cc: 55,
        extension: "xlsx"
      )
    ).to eq("reporte_utilizado_01012026_a_04092026_cc_55.xlsx")
  end
end
