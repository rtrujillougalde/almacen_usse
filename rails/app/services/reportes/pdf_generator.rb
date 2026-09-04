require "prawn"
require "prawn/table"

Prawn::Fonts::AFM.hide_m17n_warning = true

module Reportes
  # PDF layout and styling mirrored from src/p_reportes.py + src/pdf_styles.py.
  class PdfGenerator
    S = PdfStyles

    def self.movement(movement_type:, cc:, rows:)
      new.movement(movement_type: movement_type, cc: cc, rows: rows)
    end

    def self.comparativo(cc:, rows:)
      new.comparativo(cc: cc, rows: rows)
    end

    def movement(movement_type:, cc:, rows:)
      report_label = movement_type.to_s == "entrada" ? "Entradas" : "Salidas"
      generated_at = Time.current

      build_document(left_margin: 50, right_margin: 50) do |pdf|
        draw_title(pdf, "Reporte de #{report_label} de Almacén")
        pdf.move_down 14
        draw_metadata_table(pdf, generated_at, cc.presence || rows.first&.c_c)
        pdf.move_down 22

        if rows.blank?
          pdf.text "No hay datos de #{movement_type}s para mostrar.", size: 10
          next
        end

        data = [ [ "Fecha/Hora", "Material", "Cantidad", "Unidad", "Precio Unit.", "Total" ] ]
        total_general = 0.0

        rows.each do |r|
          precio = r.precio_unitario.to_f
          total = r.cantidad.to_f * precio
          total_general += total
          data << [
            r.fecha_hora&.strftime("%Y-%m-%d %H:%M").to_s,
            r.material.to_s,
            format_qty(r.cantidad),
            r.unidad_medida.to_s,
            money(precio),
            money(total)
          ]
        end

        draw_data_table(pdf, data, S::COL_WIDTHS)
        pdf.move_down 22
        pdf.fill_color S::ENTRADAS_TOTAL_COLOR
        pdf.text "<b>TOTAL GENERAL:</b> #{money_with_commas(total_general)}",
                 size: S::ENTRADAS_TOTAL_FONT_SIZE,
                 align: :right,
                 inline_format: true
        pdf.fill_color "000000"
      end
    end

    def comparativo(cc:, rows:)
      generated_at = Time.current
      metadata_cc =
        if rows.blank?
          cc
        else
          unique = rows.map { |r| r[:c_c] }.uniq
          unique.size == 1 ? unique.first : "Varios"
        end

      build_document(left_margin: 40, right_margin: 40) do |pdf|
        draw_title(pdf, "Reporte Comparativo: Entradas vs Salidas")
        pdf.move_down 14
        draw_metadata_table(pdf, generated_at, metadata_cc)
        pdf.move_down 22

        if rows.blank?
          pdf.text "No hay datos comparativos para mostrar.", size: 10
          next
        end

        sorted = rows.sort_by { |r| [ r[:c_c].to_s, r[:material].to_s ] }
        # Column order matches Python PDF (Salidas before Entradas).
        data = [ [
          "Material", "Tipo", "Unidad", "Precio Unit.",
          "Salidas", "Entradas", "Usado", "Costo Mat. Usado"
        ] ]

        sorted.each do |r|
          data << [
            r[:material].to_s,
            r[:tipo].to_s,
            r[:unidad_medida].to_s,
            money_with_commas(r[:precio_unitario]),
            format_qty(r[:total_salida]),
            format_qty(r[:total_entrada]),
            format_qty(r[:usado]),
            money_with_commas(r[:costo_material_usado])
          ]
        end

        draw_data_table(pdf, data, S::COL_WIDTHS_COMP)
        pdf.move_down 22

        total_costo = sorted.sum { |r| r[:costo_material_usado].to_f }
        pdf.fill_color S::SUMMARY_COLOR
        pdf.text "<b>Costo Total:</b> #{money_with_commas(total_costo)}",
                 size: S::SUMMARY_FONT_SIZE,
                 align: :right,
                 inline_format: true
        pdf.fill_color "000000"
      end
    end

    private

    def build_document(left_margin:, right_margin:)
      doc = Prawn::Document.new(
        page_size: "LETTER",
        left_margin: left_margin,
        right_margin: right_margin,
        top_margin: 72,
        bottom_margin: 18
      )
      yield doc
      apply_page_decorators(doc)
      doc.render
    end

    def apply_page_decorators(pdf)
      logo = S.logo_path

      pdf.page_count.times do |i|
        pdf.go_to_page(i + 1)
        first_page = i.zero?
        width = first_page ? S::LOGO_FIRST_PAGE_WIDTH : S::LOGO_LATER_PAGE_WIDTH
        height = first_page ? S::LOGO_FIRST_PAGE_HEIGHT : S::LOGO_LATER_PAGE_HEIGHT
        y_offset = first_page ? S::LOGO_FIRST_PAGE_Y_OFFSET : S::LOGO_LATER_PAGE_Y_OFFSET

        pdf.canvas do
          if logo.exist?
            # ReportLab places image bottom at page_height - y_offset.
            pdf.image logo.to_s,
                      at: [ S::LOGO_X, pdf.bounds.top - y_offset ],
                      width: width,
                      height: height
          end

          unless first_page
            pdf.fill_color S::PAGE_NUMBER_COLOR
            pdf.font_size S::PAGE_NUMBER_FONT_SIZE
            label = "Pagina #{i + 1}"
            pdf.draw_text label, at: [ pdf.bounds.right - 50, 14 ]
            pdf.fill_color "000000"
          end
        end
      end
    end

    def draw_title(pdf, text)
      pdf.fill_color S::TITLE_COLOR
      pdf.text text, size: S::TITLE_FONT_SIZE, style: :bold, align: :center
      pdf.fill_color "000000"
    end

    def draw_metadata_table(pdf, generated_at, cc_value)
      meta = [
        [ "Fecha", "Hora", "C.C" ],
        [
          generated_at.strftime("%d/%m/%Y"),
          generated_at.strftime("%H:%M:%S"),
          cc_value.present? ? cc_value.to_s : "N/A"
        ]
      ]

      pdf.table(meta, column_widths: S::COL_WIDTHS_METADATA, position: :center) do
        cells.align = :center
        cells.valign = :center
        cells.size = S::TABLE_BODY_FONT_SIZE
        cells.text_color = S::TABLE_TEXT_COLOR
        cells.border_color = S::TABLE_GRID_COLOR
        cells.border_width = 1
        row(0).font_style = :bold
        row(0).size = S::TABLE_HEADER_FONT_SIZE
        row(0).background_color = S::TABLE_HEADER_COLOR
        row(0).padding_bottom = 8
        row(1).background_color = S::TABLE_ROW_ALT_COLOR
      end
    end

    def draw_data_table(pdf, data, column_widths)
      pdf.table(data, column_widths: column_widths, header: true) do
        cells.align = :center
        cells.valign = :center
        cells.size = S::TABLE_BODY_FONT_SIZE
        cells.text_color = S::TABLE_TEXT_COLOR
        cells.border_color = S::TABLE_GRID_COLOR
        cells.border_width = 1
        row(0).font_style = :bold
        row(0).size = S::TABLE_HEADER_FONT_SIZE
        row(0).background_color = S::TABLE_HEADER_COLOR
        row(0).padding_bottom = 8

        (1...data.length).each do |idx|
          row(idx).background_color = idx.odd? ? S::TABLE_ROW_ALT_COLOR : S::TABLE_ROW_BASE_COLOR
        end
      end
    end

    def money(value)
      format("$%.2f", value.to_f)
    end

    def money_with_commas(value)
      int, dec = format("%.2f", value.to_f).split(".")
      int_with_commas = int.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
      "$#{int_with_commas}.#{dec}"
    end

    def format_qty(value)
      v = value.to_f
      (v == v.to_i) ? v.to_i.to_s : v.to_s
    end
  end
end
