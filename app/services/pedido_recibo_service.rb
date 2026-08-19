require "prawn"
require "prawn/table"

Prawn::Fonts::AFM.hide_m17n_warning = true

# Arma el PDF descargable del pedido (botón "Descargar mi pedido" en la
# pantalla de pedido confirmado/consultado) — un respaldo simple que el
# cliente puede guardar o reenviar, sin depender de que revise WhatsApp o
# email después.
class PedidoReciboService
  AZUL_FUYEN = "081f2e".freeze
  GRIS_TEXTO = "555555".freeze
  GRIS_CLARO = "f2f2f2".freeze

  def initialize(order)
    @order = order
  end

  def nombre_archivo
    "Pedido_#{@order.codigo_pedido}.pdf"
  end

  def pdf
    Prawn::Document.new(margin: 50) do |doc|
      encabezado(doc)
      datos_pedido(doc)
      tabla_productos(doc)
      totales(doc)
      direccion(doc)
      contacto(doc)
      agradecimiento(doc)
    end.render
  end

  private

  def encabezado(doc)
    doc.fill_color AZUL_FUYEN
    doc.font_size(22) { doc.text "Fuyén Ahumados", style: :bold, align: :center }
    doc.fill_color GRIS_TEXTO
    doc.font_size(10) { doc.text "Salmón ahumado artesanal", align: :center }
    doc.fill_color "000000"
    doc.move_down 16
    doc.stroke_color "cccccc"
    doc.stroke_horizontal_rule
    doc.move_down 16
  end

  def datos_pedido(doc)
    doc.font_size(16) { doc.text "Pedido #{@order.codigo_pedido}", style: :bold }
    doc.move_down 2
    doc.font_size(10) { doc.text "Fecha de entrega: viernes #{@order.fecha_entrega.strftime('%d/%m/%Y')}" }
    doc.move_down 14
  end

  def tabla_productos(doc)
    filas = [ [ "Producto", "Cantidad", "Precio unit.", "Subtotal" ] ]
    @order.order_items.each do |item|
      filas << [ item.product.nombre, item.cantidad.to_s, formato_pesos(item.precio_unitario), formato_pesos(item.subtotal) ]
    end

    doc.table(filas, header: true, width: doc.bounds.width) do |t|
      t.row(0).background_color = AZUL_FUYEN
      t.row(0).text_color = "ffffff"
      t.row(0).font_style = :bold
      t.row_colors = [ "ffffff", GRIS_CLARO ]
      t.cells.padding = 8
      t.cells.size = 10
      t.cells.borders = []
      t.columns(1..3).align = :right
    end
    doc.move_down 12
  end

  def totales(doc)
    doc.font_size(10) do
      doc.text "Subtotal productos: #{formato_pesos(@order.subtotal_productos)}", align: :right
      doc.text "Envío: #{@order.envio.zero? ? 'Gratis' : formato_pesos(@order.envio)}", align: :right
    end
    doc.font_size(13) { doc.text "Total: #{formato_pesos(@order.total)}", style: :bold, align: :right }
    doc.move_down 16
    doc.stroke_color "cccccc"
    doc.stroke_horizontal_rule
    doc.move_down 16
  end

  def direccion(doc)
    doc.font_size(11) { doc.text "Dirección de entrega", style: :bold }
    doc.font_size(10) { doc.text @order.direccion_completa }

    return if @order.notas.blank?

    doc.move_down 8
    doc.font_size(11) { doc.text "Instrucciones de entrega", style: :bold }
    doc.font_size(10) { doc.text @order.notas }
  end

  def contacto(doc)
    doc.move_down 14
    doc.font_size(11) { doc.text "Datos de contacto", style: :bold }
    doc.font_size(10) do
      doc.text @order.nombre_completo_contacto
      doc.text @order.telefono_contacto
      doc.text @order.email_contacto
    end
  end

  def agradecimiento(doc)
    doc.move_down 20
    doc.stroke_color "cccccc"
    doc.stroke_horizontal_rule
    doc.move_down 16
    doc.fill_color AZUL_FUYEN
    doc.font_size(11) do
      doc.text "¡Gracias por preferir Fuyén! Tu compra significa mucho para nosotros: " \
                "cada pedido lo ahumamos con el mismo cuidado con el que lo haríamos para " \
                "nuestra propia mesa. ¡Nos vemos el día de la entrega!",
               align: :center, style: :italic
    end
    doc.fill_color "000000"
  end

  def formato_pesos(monto)
    ActiveSupport::NumberHelper.number_to_currency(monto, unit: "$", separator: ",", delimiter: ".", precision: 0)
  end
end
