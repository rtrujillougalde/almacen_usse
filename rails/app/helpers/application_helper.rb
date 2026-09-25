module ApplicationHelper
  UNIDADES = %w[pza m lt kg tramo juego].freeze

  def page_title(title)
    content_for(:title, title)
  end

  def proyecto_label(proyecto)
    "#{proyecto.c_c} | #{proyecto.nombre_obra}"
  end

  # format is a key under time.formats in the locale file. A raw strftime
  # string still works, which is what I18n.l does with a String.
  def format_datetime(time, format: :default)
    return "N/A" if time.blank?

    l(time.in_time_zone, format: format)
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
