class AccesoController < ApplicationController
  skip_before_action :verificar_acceso

  def entrar
    token = params[:token]

    if AccessToken.valido?(token)
      session[:acceso_token] = token
      cookies[:acceso_token] = { value: token, expires: 1.year.from_now, httponly: true }
      redirect_to root_path, notice: "Bienvenido a Fuyén."
    else
      render :invalido, status: :forbidden
    end
  end

  def invalido
  end

  def bienvenida
  end
end
