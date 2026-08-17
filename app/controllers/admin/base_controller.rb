class Admin::BaseController < ApplicationController
  layout "admin"
  before_action :authenticate_user!
  before_action :verificar_admin

  private

  def verificar_admin
    redirect_to root_path, alert: "No tienes acceso a esta sección." unless current_user.admin?
  end
end
