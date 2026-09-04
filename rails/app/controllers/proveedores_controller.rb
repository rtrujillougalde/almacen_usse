class ProveedoresController < ApplicationController
  before_action -> { authorize_page!("proveedores") }

  def index
  end
end
