class InventarioController < ApplicationController
  before_action :authorize_page!

  def index
    @articulos = Articulo.includes(:proveedor_record)
                         .alphabetical
                         .with_tipo(params[:tipo])
                         .nombre_matching(params[:nombre])
    @tipos = [ Articulo::ALL_TIPOS ] + Articulo.tipos.keys
  end
end
