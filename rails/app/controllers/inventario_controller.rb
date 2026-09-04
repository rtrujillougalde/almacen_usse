class InventarioController < ApplicationController
  before_action -> { authorize_page!("inventario") }

  def index
  end
end
