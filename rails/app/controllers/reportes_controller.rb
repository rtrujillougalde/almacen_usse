class ReportesController < ApplicationController
  before_action -> { authorize_page!("reportes") }

  def index
  end
end
