class CheckoutController < ApplicationController
  before_action :solo_clientes
  before_action :verificar_carrito_no_vacio

  def show
    @order = nuevo_pedido_prellenado
    @direcciones = user_signed_in? ? current_user.direcciones.order(created_at: :asc) : Direccion.none
  end

  def create
    @order = pedido_del_titular.new(checkout_params.merge(envio: carrito_envio, total: carrito_gran_total))

    if @order.invalid?
      @direcciones = user_signed_in? ? current_user.direcciones.order(created_at: :asc) : Direccion.none
      render :show, status: :unprocessable_entity and return
    end

    ubicar_direccion(@order)

    ActiveRecord::Base.transaction do
      @order.save!

      carrito_items.each do |item|
        @order.order_items.create!(
          product:         item[:product],
          cantidad:        item[:cantidad],
          precio_unitario: item[:product].precio
        )
        item[:product].decrement!(:stock, item[:cantidad])
      end
    end

    session.delete(:carrito)
    redirect_to pedido_publico_path(@order.codigo_pedido), notice: "Pedido creado. Ahora confirma por WhatsApp."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to checkout_path, alert: "Error al crear el pedido: #{e.message}"
  end

  private

  # Best-effort: intenta ubicar la dirección para guardar lat/lng de referencia,
  # pero nunca bloquea el pedido — si Nominatim no la encuentra o no responde,
  # el pedido se confirma igual. Cualquier error de dirección se corrige a mano
  # por el negocio (WhatsApp), no exigiéndoselo al cliente en el formulario.
  def ubicar_direccion(order)
    resultado = GeocodificadorService.buscar(order.direccion_calle, order.direccion_comuna)
    return unless resultado&.encontrada

    order.lat = resultado.lat
    order.lng = resultado.lng
  end

  # La fecha de entrega no se prellena a propósito — el cliente tiene que
  # elegirla a mano siempre, para no arriesgarse a que quede la más próxima
  # sin querer (a pedido de Joaquín).
  def nuevo_pedido_prellenado
    return Order.new unless user_signed_in?

    current_user.orders.new(
      nombre_contacto:   current_user.nombre,
      apellido_contacto: current_user.apellido,
      telefono_contacto: current_user.telefono,
      email_contacto:    current_user.email,
      direccion_calle:   current_user.direccion_principal&.calle,
      direccion_numero_depto: current_user.direccion_principal&.numero_depto,
      direccion_comuna:  current_user.direccion_principal&.comuna
    )
  end

  def pedido_del_titular
    user_signed_in? ? current_user.orders : Order
  end

  def checkout_params
    params.require(:order).permit(
      :nombre_contacto, :apellido_contacto, :telefono_contacto, :email_contacto,
      :direccion_calle, :direccion_numero_depto, :direccion_comuna, :notas, :fecha_entrega
    )
  end

  def verificar_carrito_no_vacio
    if carrito_items.empty?
      redirect_to root_path, alert: "Tu carrito está vacío."
    end
  end
end
