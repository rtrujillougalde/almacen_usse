class ProyectosController < ApplicationController
  before_action -> { authorize_page!("proyectos") }

  def index
  end
end
