class DireccionesController < ApplicationController
  before_action :authenticate_user!
  before_action :solo_clientes
  before_action :set_direccion, only: [ :edit, :update, :destroy ]

  def new
    @direccion = current_user.direcciones.build
  end

  def create
    @direccion = current_user.direcciones.build(direccion_params)

    if @direccion.save
      redirect_to perfil_path, notice: "Dirección agregada."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @direccion.update(direccion_params)
      redirect_to perfil_path, notice: "Dirección actualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if current_user.direcciones.one?
      redirect_to perfil_path, alert: "Debes tener al menos una dirección guardada."
    else
      @direccion.destroy
      redirect_to perfil_path, notice: "Dirección eliminada."
    end
  end

  private

  def set_direccion
    @direccion = current_user.direcciones.find(params[:id])
  end

  def direccion_params
    params.require(:direccion).permit(:etiqueta, :comuna, :calle, :numero_depto, :principal)
  end
end
