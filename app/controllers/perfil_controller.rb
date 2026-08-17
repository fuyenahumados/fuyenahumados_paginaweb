class PerfilController < ApplicationController
  before_action :authenticate_user!
  before_action :solo_clientes

  def show
    @pedidos = current_user.orders.order(created_at: :desc)
  end

  def edit
  end

  def update
    if current_user.update(perfil_params)
      redirect_to perfil_path, notice: "Tus datos fueron actualizados."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def perfil_params
    params.require(:user).permit(:nombre, :apellido, :telefono)
  end
end
