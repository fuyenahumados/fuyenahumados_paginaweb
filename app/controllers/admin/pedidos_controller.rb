class Admin::PedidosController < Admin::BaseController
  before_action :set_pedido, only: [ :show, :avanzar_estado, :cancelar ]

  FLUJO_ESTADOS = {
    "pendiente_pago" => "pagado",
    "pagado"         => "en_preparacion",
    "en_preparacion" => "despachado",
    "despachado"     => "entregado"
  }.freeze

  def index
    @pedidos = Order.includes(:user, :order_items).order(created_at: :desc)
    @proximo_despacho = Order.proximo_viernes_habil

    if params[:fecha].present?
      @fecha_filtro = Date.parse(params[:fecha])
      @pedidos = @pedidos.where(fecha_entrega: @fecha_filtro)
    end

    @buscar = params[:buscar]
    if @buscar.present?
      termino = "%#{@buscar}%"
      @pedidos = @pedidos.left_joins(:user).where(
        "orders.codigo_pedido ILIKE :t
         OR orders.nombre_contacto ILIKE :t OR orders.apellido_contacto ILIKE :t
         OR (orders.nombre_contacto || ' ' || orders.apellido_contacto) ILIKE :t
         OR orders.email_contacto ILIKE :t
         OR users.nombre ILIKE :t OR users.apellido ILIKE :t
         OR (users.nombre || ' ' || users.apellido) ILIKE :t
         OR users.email ILIKE :t",
        t: termino
      )
    end
  rescue Date::Error, TypeError
    redirect_to admin_pedidos_path, alert: "Fecha inválida."
  end

  def exportar
    fecha_despacho = Date.parse(params[:fecha_despacho])
    servicio = PedidosExcelExportService.new(fecha_despacho)

    send_data servicio.generar,
              filename: servicio.nombre_archivo,
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
              disposition: "attachment"
  rescue Date::Error, TypeError
    redirect_to admin_pedidos_path, alert: "Fecha de despacho inválida."
  end

  def show
  end

  def new
    @order = Order.new
    @order.order_items.build
    cargar_datos_formulario
  end

  def create
    @order = Order.new(pedido_manual_params)
    @order.source = "manual"
    aplicar_precios_unitarios(@order)
    calcular_totales(@order)

    if @order.save
      decrementar_stock(@order)
      redirect_to admin_pedido_path(@order), notice: "Pedido manual #{@order.codigo_pedido} creado."
    else
      cargar_datos_formulario
      render :new, status: :unprocessable_entity
    end
  end

  def avanzar_estado
    siguiente = FLUJO_ESTADOS[@pedido.estado]
    if siguiente
      @pedido.update!(estado: siguiente)
      redirect_to admin_pedido_path(@pedido), notice: "Estado actualizado: #{helpers.estado_label(siguiente)}."
    else
      redirect_to admin_pedido_path(@pedido), alert: "No se puede avanzar el estado."
    end
  end

  def cancelar
    if @pedido.entregado? || @pedido.cancelado?
      redirect_to admin_pedido_path(@pedido), alert: "No se puede cancelar este pedido."
    else
      @pedido.cancelado!
      redirect_to admin_pedido_path(@pedido), notice: "Pedido cancelado."
    end
  end

  private

  def set_pedido
    @pedido = Order.includes(:user, order_items: :product).find(params[:id])
  end

  def cargar_datos_formulario
    @clientes = User.cliente.order(:nombre, :apellido)
    @productos = Product.disponibles.order(:nombre)
    @proximo_viernes = Order.proximo_viernes_habil
  end

  # El precio se fija siempre desde el precio actual del producto, no desde lo
  # que mande el formulario — mismo criterio que el checkout normal (nunca se
  # confía en un precio que pueda venir editado desde el cliente).
  def aplicar_precios_unitarios(order)
    order.order_items.each do |item|
      item.precio_unitario = item.product.precio if item.product
    end
  end

  def calcular_totales(order)
    subtotal = order.subtotal_productos
    order.envio = CostoEnvio.calcular(subtotal)
    order.total = subtotal + order.envio
  end

  def decrementar_stock(order)
    order.order_items.each { |item| item.product.decrement!(:stock, item.cantidad) }
  end

  def pedido_manual_params
    params.require(:order).permit(
      :user_id, :nombre_contacto, :apellido_contacto, :telefono_contacto, :email_contacto,
      :direccion_calle, :direccion_numero_depto, :direccion_comuna, :notas, :fecha_entrega, :estado,
      order_items_attributes: [ :product_id, :cantidad ]
    )
  end
end
