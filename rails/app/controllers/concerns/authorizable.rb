module Authorizable
  extend ActiveSupport::Concern

  included do
    helper_method :nav_pages_for_current_user
  end

  private

  def authorize_page!(page = controller_name)
    return if current_user&.can_access?(page)

    deny_access!
  end

  def require_system!(system)
    return if current_user&.enters?(system)

    deny_access!
  end

  def deny_access!
    redirect_to access_denied_path,
                alert: "No tienes permiso para acceder a esta sección."
  end

  def access_denied_path
    return warehouse_home_path if current_user&.enters?(:almacen)
    return control_personal_path if current_user&.enters?(:personal)

    root_path
  end

  def warehouse_home_path
    page = current_user.first_allowed_page
    path_helper = User::PAGE_PATHS[page]
    path_helper ? send(path_helper) : inventario_path
  end

  def nav_pages_for_current_user
    return [] unless current_user

    current_user.allowed_pages
  end
end
