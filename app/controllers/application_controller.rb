class ApplicationController < ActionController::Base
  include CarritoConcern

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :verificar_acceso
  before_action :configure_permitted_parameters, if: :devise_controller?

  after_action { response.headers["X-Robots-Tag"] = "noindex, nofollow" }

  private

  # Desactiva los flashes automáticos de Devise (login/logout/registro, etc.)
  # sin afectar los flashes propios de la app (notice/alert en redirect_to).
  def is_flashing_format?
    false
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :nombre, :apellido, :telefono,
      direcciones_attributes: [ :etiqueta, :comuna, :calle, :numero_depto ]
    ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :nombre, :apellido, :telefono ])
  end

  def verificar_acceso
    if session[:acceso_token].nil? && AccessToken.valido?(cookies[:acceso_token])
      session[:acceso_token] = cookies[:acceso_token]
    end
    return if AccessToken.valido?(session[:acceso_token])

    redirect_to acceso_invalido_path
  end

  def solo_clientes
    if user_signed_in? && current_user.admin?
      redirect_to admin_root_path, alert: "Esta sección es solo para clientes."
    end
  end
end
