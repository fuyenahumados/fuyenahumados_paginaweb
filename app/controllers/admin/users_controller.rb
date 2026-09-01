class Admin::UsersController < Admin::BaseController
  def index
    @usuarios = User.cliente.includes(:direcciones).order(:nombre, :apellido)
    @buscar = params[:buscar]

    if @buscar.present?
      termino = "%#{@buscar}%"
      @usuarios = @usuarios.where(
        "nombre ILIKE :t OR apellido ILIKE :t OR (nombre || ' ' || apellido) ILIKE :t OR email ILIKE :t OR telefono ILIKE :t",
        t: termino
      )
    end
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

  # No hay recuperación de contraseña por email (el sitio no tiene SMTP configurado) —
  # el cliente pide el reseteo por WhatsApp y el admin genera acá una contraseña
  # nueva para pasarle a mano en esa misma conversación.
  def resetear_password
    usuario = User.cliente.find(params[:id])
    nueva_password = SecureRandom.alphanumeric(10)
    usuario.update!(password: nueva_password, password_confirmation: nueva_password)

    redirect_to admin_user_path(usuario),
      notice: "Contraseña reseteada. Nueva contraseña para pasarle al cliente por WhatsApp: #{nueva_password}"
  end
end
