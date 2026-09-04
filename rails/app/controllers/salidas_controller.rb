class SalidasController < ApplicationController
  before_action -> { authorize_page!("salidas") }

  def index
  end
end
