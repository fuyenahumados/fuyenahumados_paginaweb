class Users::RegistrationsController < Devise::RegistrationsController
  protected

  def after_update_path_for(resource)
    perfil_path
  end
end
