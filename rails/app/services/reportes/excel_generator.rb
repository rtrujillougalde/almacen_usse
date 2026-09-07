require "caxlsx"

module Reportes
  # Excel layout mirrored from src/p_reportes.py (openpyxl table + currency format).
  class ExcelGenerator
    CURRENCY_FORMAT = '[$$-es-MX]#,##0.00'
    MATERIAL_WIDTH = 46

    def self.movement(movement_type:, rows:)
      new.movement(movement_type: movement_type, rows: rows)
    end

    def self.utilizado(groups:)
      new.utilizado(groups: groups)
    end

    def movement(movement_type:, rows:)
      compra = movement_type.to_s == "compra"
      sheet_name = { "entrada" => "Entradas", "salida" => "Salidas", "compra" => "Compras" }.fetch(movement_type.to_s, "Movimientos")
      package = Axlsx::Package.new
      workbook = package.workbook
      styles = build_styles(workbook)

      workbook.add_worksheet(name: sheet_name) do |sheet|
        headers = [ "Fecha/Hora", "C.C", "Material", "Cantidad", "Unidad" ]
        headers += [ "Precio Unit.", "Proveedor", "Moneda" ] if compra
        sheet.add_row headers, style: styles[:header]

        rows.each do |r|
          values = [
            r.fecha_hora&.strftime("%Y-%m-%d %H:%M:%S").to_s,
            r.c_c,
            r.material.to_s,
            r.cantidad.to_f,
            r.unidad_medida.to_s
          ]
          values += [ r.precio_unitario.to_f, r.proveedor.to_s, r.moneda.to_s ] if compra
          row_styles = Array.new(values.length, styles[:body])
          row_styles[5] = styles[:currency] if compra
          sheet.add_row(values, style: row_styles)
        end

        finalize_sheet!(sheet, headers: headers, table_name: "Tabla_#{sheet_name}")
      end

      package.to_stream.read
    end

    def utilizado(groups:)
      package = Axlsx::Package.new
      workbook = package.workbook
      styles = build_styles(workbook)

      groups.each do |group|
        workbook.add_worksheet(name: group[:moneda].to_s) do |sheet|
          headers = [
            "C.C", "Material", "Tipo", "Unidad", "Precio Unit.",
            "Compras", "Salidas", "Entradas", "Utilizado", "Costo"
          ]
          sheet.add_row headers, style: styles[:header]

          sorted = group[:rows].sort_by { |r| [ r[:c_c].to_s, r[:material].to_s ] }
          sorted.each do |r|
            sheet.add_row(
              [
                r[:c_c],
                r[:material],
                r[:tipo],
                r[:unidad_medida],
                r[:precio_unitario].to_f,
                r[:total_compra].to_f,
                r[:total_salida].to_f,
                r[:total_entrada].to_f,
                r[:utilizado].to_f,
                r[:costo].to_f
              ],
              style: [
                styles[:body], styles[:body], styles[:body], styles[:body],
                styles[:currency], styles[:body], styles[:body], styles[:body],
                styles[:body], styles[:currency]
              ]
            )
          end

          finalize_sheet!(sheet, headers: headers, table_name: "Tabla_#{group[:moneda]}")
        end
      end

      package.to_stream.read
    end

    private

    def build_styles(workbook)
      center = { horizontal: :center, vertical: :center, wrap_text: true }
      row_border = { style: :thin, color: "D3D3D3", edges: [ :top, :bottom ] }

      {
        header: workbook.styles.add_style(alignment: center, border: row_border, b: true),
        body: workbook.styles.add_style(alignment: center, border: row_border),
        currency: workbook.styles.add_style(
          alignment: center,
          border: row_border,
          format_code: CURRENCY_FORMAT
        )
      }
    end

    def finalize_sheet!(sheet, headers:, table_name:)
      material_idx = headers.index("Material")
      sheet.column_info[material_idx].width = MATERIAL_WIDTH if material_idx

      return if sheet.rows.length < 1 || headers.empty?

      last_col = Axlsx.col_ref(headers.length - 1)
      last_row = sheet.rows.length
      safe_name = table_name.gsub(/[^0-9A-Za-z_]/, "_")
      safe_name = "T_#{safe_name}" if safe_name.match?(/\A\d/)

      sheet.add_table "A1:#{last_col}#{last_row}",
                      name: safe_name,
                      style_info: {
                        name: "TableStyleMedium2",
                        show_first_column: false,
                        show_last_column: false,
                        show_row_stripes: true,
                        show_column_stripes: false
                      }
    end
  end
end
