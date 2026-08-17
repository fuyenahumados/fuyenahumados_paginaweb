class Admin::UsersController < Admin::BaseController
  def index
    @usuarios = User.cliente.includes(:direcciones).order(:nombre, :apellido)
  end

  def show
    @usuario = User.cliente.find(params[:id])
    @pedidos = @usuario.orders.order(created_at: :desc)
  end

  def destroy
    usuario = User.cliente.find(params[:id])

    if usuario.orders.exists?
      redirect_to admin_user_path(usuario), alert: "No se puede eliminar: este cliente tiene pedidos asociados."
    else
      usuario.destroy
      redirect_to admin_users_path, notice: "Usuario eliminado."
    end
  end
end
