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

  def avanzar_estado
    siguiente = FLUJO_ESTADOS[@pedido.estado]
    if siguiente
      @pedido.update!(estado: siguiente)
      redirect_to admin_pedido_path(@pedido), notice: "Estado actualizado: #{estado_label(siguiente)}."
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
end
