module ApplicationHelper
  UNIDADES = %w[pza m lt kg tramo juego].freeze

  def page_title(title)
    content_for(:title, title)
  end

  def proyecto_label(proyecto)
    "#{proyecto.c_c} | #{proyecto.nombre_obra}"
  end

  def generate_button_label(kind)
    case kind.to_s
    when "salida" then "Generar Reporte de Salidas"
    when "compra" then "Generar Reporte de Compras"
    when "utilizado" then "Generar Reporte de Material Utilizado"
    else "Generar Reporte de Entradas"
    end
  end
end
