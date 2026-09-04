module Authorizable
  extend ActiveSupport::Concern

  included do
    helper_method :nav_pages_for_current_user
  end

  private

  def authorize_page!(page = controller_name)
    return if current_user&.can_access?(page)

    redirect_to after_sign_in_path_for(current_user),
                alert: "No tienes permiso para acceder a esta sección."
  end

  def nav_pages_for_current_user
    return [] unless current_user

    current_user.allowed_pages
  end
end
