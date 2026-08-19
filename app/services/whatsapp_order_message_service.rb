# Arma el mensaje pre-escrito y el link wa.me para que el cliente pida los
# datos de pago de su pedido por WhatsApp. Los datos bancarios se los pasa
# el negocio a mano en esa conversación, nunca se muestran ni se envían
# automáticamente.
class WhatsappOrderMessageService
  def initialize(order)
    @order = order
  end

  def url
    "https://wa.me/#{numero}?text=#{ERB::Util.url_encode(texto)}"
  end

  def texto
    [
      "Hola, soy #{@order.nombre_completo_contacto} y quiero confirmar mi pedido #{@order.codigo_pedido}:",
      "",
      *items_texto,
      "",
      "Subtotal productos: #{formato_pesos(@order.subtotal_productos)}",
      "Envío: #{@order.envio.zero? ? "Gratis" : formato_pesos(@order.envio)}",
      "Total: #{formato_pesos(@order.total)}",
      "Fecha de entrega: viernes #{@order.fecha_entrega.strftime('%d/%m/%Y')}",
      "Dirección de entrega: #{@order.direccion_completa}",
      "",
      "Quedo atento/a a los datos para pagar. Muchas gracias!"
    ].join("\n")
  end

  private

  def items_texto
    @order.order_items.map do |item|
      "- #{item.product.nombre} x#{item.cantidad} (#{formato_pesos(item.subtotal)})"
    end
  end

  def formato_pesos(monto)
    ActiveSupport::NumberHelper.number_to_currency(monto, unit: "$", separator: ",", delimiter: ".", precision: 0)
  end

  def numero
    CONTACTO[:whatsapp]
  end
end
