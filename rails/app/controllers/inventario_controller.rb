class InventarioController < ApplicationController
  before_action -> { authorize_page!("inventario") }

  def index
    scope = Articulo.includes(:proveedor_record).order(:nombre)
    if params[:categoria].present? && params[:categoria] != "Todas"
      scope = scope.where(categoria: params[:categoria])
    end
    if params[:tipo].present? && params[:tipo] != "Todos"
      scope = scope.where(tipo: params[:tipo])
    end
    if params[:nombre].present?
      scope = scope.where("LOWER(nombre) LIKE ?", "%#{params[:nombre].downcase}%")
    end
    @articulos = scope
    @categorias = [ "Todas" ] + Articulo::CATEGORIAS
    @tipos = [ "Todos", "material", "herramienta" ]
  end
end
