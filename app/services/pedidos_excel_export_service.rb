# Genera el Excel de los pedidos de una fecha de entrega puntual (un viernes de
# despacho), no solo los pagados, para que el negocio vea de un vistazo lo que
# hay que preparar ese día, con una columna de estado para distinguir qué está
# pagado y qué no. Se genera al vuelo desde el panel admin (send_data) — Render
# tiene filesystem efímero, no se guarda en disco.
class PedidosExcelExportService
  MESES_ES = %w[
    enero febrero marzo abril mayo junio julio
    agosto septiembre octubre noviembre diciembre
  ].freeze

  def initialize(fecha_despacho)
    @fecha_despacho = fecha_despacho
  end

  def nombre_archivo
    "Pedido_#{fecha_formateada}.xlsx"
  end

  def generar
    pedidos = Order.where(fecha_entrega: @fecha_despacho)
                    .where.not(estado: :cancelado)
                    .includes(order_items: :product)
                    .order(created_at: :asc)

    package = Axlsx::Package.new
    package.workbook.add_worksheet(name: nombre_hoja) do |sheet|
      sheet.add_row [
        "Código", "Cliente", "Teléfono", "Dirección", "Instrucciones de entrega",
        "Productos y cantidades", "Subtotal productos", "Envío", "Total", "Estado"
      ]

      pedidos.each do |pedido|
        sheet.add_row [
          pedido.codigo_pedido,
          pedido.nombre_completo_contacto,
          pedido.telefono_contacto,
          pedido.direccion_completa,
          pedido.notas,
          productos_y_cantidades(pedido),
          pedido.subtotal_productos.to_f,
          pedido.envio.to_f,
          pedido.total.to_f,
          ApplicationHelper::ESTADO_LABELS.fetch(pedido.estado, pedido.estado)
        ]
      end
    end

    package.to_stream.read
  end

  private

  def productos_y_cantidades(pedido)
    pedido.order_items.map do |item|
      "#{item.product.nombre} x#{item.cantidad} (#{item.product.peso_descripcion})"
    end.join("; ")
  end

  def nombre_hoja
    "Pedido_#{fecha_formateada}"[0, 31]
  end

  def fecha_formateada
    "#{@fecha_despacho.day}_de_#{MESES_ES[@fecha_despacho.month - 1]}"
  end
end
