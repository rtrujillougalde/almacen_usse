module ApplicationHelper
  UNIDADES = %w[pza m lt kg tramo juego].freeze

  def page_title(title)
    content_for(:title, title)
  end

  def proyecto_label(proyecto)
    "#{proyecto.c_c} | #{proyecto.nombre_obra}"
  end
end
