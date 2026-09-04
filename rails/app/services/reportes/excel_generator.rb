require "caxlsx"

module Reportes
  class ExcelGenerator
    def self.movement(title:, cc:, rows:)
      package = Axlsx::Package.new
      package.workbook.add_worksheet(name: title[0, 31]) do |sheet|
        sheet.add_row [ "Almacén USSE", title, "C.C.", cc ]
        sheet.add_row [ "Fecha/Hora", "Material", "Cantidad", "Unidad", "Precio", "Total" ]
        grand = 0.0
        rows.each do |r|
          precio = r.precio_unitario.to_f
          total = r.cantidad.to_f * precio
          grand += total
          sheet.add_row [ r.fecha_hora, r.material, r.cantidad, r.unidad_medida, precio, total ]
        end
        sheet.add_row [ "", "", "", "", "TOTAL", grand ]
      end
      package.to_stream.read
    end

    def self.comparativo(cc:, rows:)
      package = Axlsx::Package.new
      package.workbook.add_worksheet(name: "Comparativo") do |sheet|
        sheet.add_row [ "Almacén USSE", "Comparativo", "C.C.", cc ]
        sheet.add_row [ "Material", "Tipo", "Unidad", "Precio", "Entradas", "Salidas", "Usado", "Costo" ]
        grand = 0.0
        rows.each do |r|
          grand += r[:costo_material_usado].to_f
          sheet.add_row [
            r[:material], r[:tipo], r[:unidad_medida], r[:precio_unitario],
            r[:total_entrada], r[:total_salida], r[:usado], r[:costo_material_usado]
          ]
        end
        sheet.add_row [ "", "", "", "", "", "", "TOTAL", grand ]
      end
      package.to_stream.read
    end
  end
end
