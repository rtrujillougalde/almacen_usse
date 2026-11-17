class ControlPersonalController < ApplicationController
  layout "portal"

  before_action -> { require_system!(:personal) }

  def index
  end
end
