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
  end

  describe ".comparativo" do
    it "creates a valid PDF with comparativo columns and costo total" do
      rows = [ {
        c_c: 111,
        material: "Cemento",
        tipo: "material",
        unidad_medida: "pza",
        precio_unitario: 10,
        total_entrada: 5,
        total_salida: 8,
        usado: 3,
        costo_material_usado: 30
      } ]

      pdf = described_class.comparativo(cc: 111, rows: rows)
      text = pdf_text(pdf)

      expect(pdf).to start_with("%PDF")
      expect(pdf).to include("%%EOF")
      expect(text).to include("Reporte Comparativo: Entradas vs Salidas")
      expect(text).to include("Material")
      expect(text).to include("Tipo")
      expect(text).to include("Salidas")
      expect(text).to include("Entradas")
      expect(text).to include("Usado")
      expect(text).to include("Costo Mat.") # wraps before "Usado" in PDF layout
      expect(text).to include("Cemento")
      expect(text).to include("material")
      expect(text).to include("pza")
      expect(text).to include("$10.00")
      expect(text).to include("Costo Total:")
      expect(text).to include("$30.00")
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
  end

  describe ".comparativo" do
    it "creates an XLSX with Comparativo sheet and Python column order" do
      rows = [ {
        c_c: 222,
        material: "Pintura Azul",
        tipo: "material",
        unidad_medida: "lt",
        precio_unitario: 4.5,
        total_entrada: 10,
        total_salida: 3,
        usado: -7,
        costo_material_usado: -31.5
      } ]

      xlsx = described_class.comparativo(rows: rows)

      expect(xlsx[0, 2]).to eq("PK")
      expect(xlsx_sheet_names(xlsx)).to eq([ "Comparativo" ])

      table = xlsx_rows(xlsx)
      expect(table.first).to eq(
        [
          "C.C", "Material", "Tipo", "Unidad", "Precio Unit.",
          "Entradas", "Salidas", "Usado", "Costo Mat. Usado"
        ]
      )
      expect(table[1][0]).to eq("222")
      expect(table[1][1]).to eq("Pintura Azul")
      expect(table[1][5].to_f).to eq(10.0)
      expect(table[1][6].to_f).to eq(3.0)
      expect(table[1][8].to_f).to eq(-31.5)
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
        report_type: "comparativo",
        date_from: "2026-01-01",
        date_to: "2026-09-04",
        cc: 55,
        extension: "xlsx"
      )
    ).to eq("reporte_comparativo_01012026_a_04092026_cc_55.xlsx")
  end
end
