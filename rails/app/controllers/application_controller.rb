class ApplicationController < ActionController::Base
  include Authorizable

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :authenticate_user!, unless: :devise_controller?
  layout :resolve_layout

  private

  def resolve_layout
    devise_controller? ? "devise" : "application"
  end

  def after_sign_in_path_for(resource)
    page = resource.first_allowed_page
    path_helper = User::PAGE_PATHS[page]
    path_helper ? send(path_helper) : root_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end
end
