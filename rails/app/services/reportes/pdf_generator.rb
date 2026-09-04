require "prawn"
require "prawn/table"

Prawn::Fonts::AFM.hide_m17n_warning = true

module Reportes
  class PdfGenerator
    def self.movement(title:, cc:, rows:)
      Prawn::Document.new(page_size: "LETTER") do |pdf|
        pdf.text "Almacén USSE — #{title}", size: 16, style: :bold
        pdf.text "C.C.: #{cc}  |  Generado: #{Time.current.strftime('%Y-%m-%d %H:%M')}", size: 10
        pdf.move_down 12

        data = [ [ "Fecha/Hora", "Material", "Cantidad", "Unidad", "Precio", "Total" ] ]
        grand = 0.0
        rows.each do |r|
          precio = r.precio_unitario.to_f
          total = r.cantidad.to_f * precio
          grand += total
          data << [
            r.fecha_hora&.strftime("%Y-%m-%d %H:%M").to_s,
            r.material.to_s,
            format("%.2f", r.cantidad.to_f),
            r.unidad_medida.to_s,
            format("%.2f", precio),
            format("%.2f", total)
          ]
        end
        data << [ "", "", "", "", "TOTAL", format("%.2f", grand) ]

        pdf.table(data, header: true, width: pdf.bounds.width) do
          row(0).font_style = :bold
          columns(2..5).align = :right
        end
      end.render
    end

    def self.comparativo(cc:, rows:)
      Prawn::Document.new(page_size: "LETTER") do |pdf|
        pdf.text "Almacén USSE — Comparativo", size: 16, style: :bold
        pdf.text "C.C.: #{cc}  |  Generado: #{Time.current.strftime('%Y-%m-%d %H:%M')}", size: 10
        pdf.move_down 12

        data = [ [ "Material", "Tipo", "Unidad", "Precio", "Entradas", "Salidas", "Usado", "Costo" ] ]
        grand = 0.0
        rows.each do |r|
          grand += r[:costo_material_usado].to_f
          data << [
            r[:material], r[:tipo], r[:unidad_medida].to_s,
            format("%.2f", r[:precio_unitario]),
            format("%.2f", r[:total_entrada]),
            format("%.2f", r[:total_salida]),
            format("%.2f", r[:usado]),
            format("%.2f", r[:costo_material_usado])
          ]
        end
        data << [ "", "", "", "", "", "", "TOTAL", format("%.2f", grand) ]

        pdf.table(data, header: true, width: pdf.bounds.width) do
          row(0).font_style = :bold
          columns(3..7).align = :right
        end
      end.render
    end
  end
end
