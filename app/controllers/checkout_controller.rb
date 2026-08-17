class CheckoutController < ApplicationController
  before_action :solo_clientes
  before_action :verificar_carrito_no_vacio

  def show
    @order = nuevo_pedido_prellenado
  end

  def create
    @order = pedido_del_titular.new(checkout_params.merge(envio: carrito_envio, total: carrito_gran_total))

    if @order.invalid?
      render :show, status: :unprocessable_entity and return
    end

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

  def nuevo_pedido_prellenado
    fecha_entrega = Order.proximo_viernes_habil
    return Order.new(fecha_entrega: fecha_entrega) unless user_signed_in?

    current_user.orders.new(
      nombre_contacto:   current_user.nombre,
      apellido_contacto: current_user.apellido,
      telefono_contacto: current_user.telefono,
      email_contacto:    current_user.email,
      direccion_calle:   current_user.direccion_principal&.calle,
      direccion_comuna:  current_user.direccion_principal&.comuna,
      fecha_entrega:     fecha_entrega
    )
  end

  def pedido_del_titular
    user_signed_in? ? current_user.orders : Order
  end

  def checkout_params
    params.require(:order).permit(
      :nombre_contacto, :apellido_contacto, :telefono_contacto, :email_contacto,
      :direccion_calle, :direccion_comuna, :notas, :fecha_entrega
    )
  end

  def verificar_carrito_no_vacio
    if carrito_items.empty?
      redirect_to root_path, alert: "Tu carrito está vacío."
    end
  end
end
