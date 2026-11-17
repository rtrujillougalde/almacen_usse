class ControlPersonalController < ApplicationController
  before_action -> { require_system!(:personal) }

  def index
    redirect_to trabajadores_path
  end
end
