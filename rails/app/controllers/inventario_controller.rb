class InventarioController < ApplicationController
  before_action :authorize_page!

  def index
    @articulos = Articulo.includes(:proveedor_record)
                         .alphabetical
                         .with_categoria(params[:categoria])
                         .with_tipo(params[:tipo])
                         .nombre_matching(params[:nombre])
    @categorias = [ Articulo::ALL_CATEGORIAS ] + Articulo::CATEGORIAS
    @tipos = [ Articulo::ALL_TIPOS ] + Articulo.tipos.keys
  end
end
