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
    when "comparativo" then "Generar Reporte Comparativo"
    else "Generar Reporte de Entradas"
    end
  end
end
