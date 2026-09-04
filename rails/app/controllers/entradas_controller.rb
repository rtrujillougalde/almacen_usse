class EntradasController < ApplicationController
  before_action -> { authorize_page!("entradas") }

  def index
  end
end
