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
  BORDE_CLARO = "e0e0e0".freeze

  def initialize(order)
    @order = order
  end

  def nombre_archivo
    "Pedido_#{@order.codigo_pedido}.pdf"
  end

  def pdf
    Prawn::Document.new(margin: 50) do |doc|
      encabezado(doc)
      agradecimiento(doc)
      datos_pedido(doc)
      tabla_productos(doc)
      informacion_adicional(doc)
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
  end

  # Arriba de todo (antes del detalle del pedido), a pedido de Joaquín — es
  # lo primero que lee el cliente al abrir el PDF. Justificado (no centrado)
  # como el resto del texto corrido del documento, para que se sienta parte
  # del mismo documento prolijo y no un cartel aparte.
  def agradecimiento(doc)
    doc.fill_color AZUL_FUYEN
    doc.font_size(11) do
      doc.text "¡Gracias por preferir Fuyén! Tu compra significa mucho para nosotros: " \
                "cada pedido lo ahumamos con el mismo cuidado con el que lo haríamos para " \
                "nuestra propia mesa. ¡Nos vemos el día de la entrega!",
               align: :justify
    end
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

  # Subtotal/envío/total van DENTRO de la misma tabla (antes quedaban como
  # texto suelto debajo, fuera de la tabla) — el total queda resaltado con el
  # mismo azul del encabezado, para que no se pierda entre el resto.
  def tabla_productos(doc)
    filas = [ [ "Producto", "Cantidad", "Precio unit.", "Subtotal" ] ]

    @order.order_items.each do |item|
      filas << [ item.product.nombre, item.cantidad.to_s, formato_pesos(item.precio_unitario), formato_pesos(item.subtotal) ]
    end

    fila_subtotal = filas.size
    filas << [ { content: "Subtotal productos", colspan: 3, align: :right },
               { content: formato_pesos(@order.subtotal_productos), align: :right } ]
    filas << [ { content: "Envío", colspan: 3, align: :right },
               { content: @order.envio.zero? ? "Gratis" : formato_pesos(@order.envio), align: :right } ]
    fila_total = filas.size
    filas << [ { content: "Total", colspan: 3, align: :right, font_style: :bold },
               { content: formato_pesos(@order.total), align: :right, font_style: :bold } ]

    doc.table(filas, header: true, width: doc.bounds.width) do |t|
      t.row(0).background_color = AZUL_FUYEN
      t.row(0).text_color = "ffffff"
      t.row(0).font_style = :bold
      t.cells.padding = 8
      t.cells.size = 10
      t.cells.borders = [ :bottom ]
      t.cells.border_color = BORDE_CLARO
      t.columns(1..3).align = :right

      (1...fila_subtotal).each do |fila|
        t.row(fila).background_color = fila.odd? ? GRIS_CLARO : "ffffff"
      end
      t.row(fila_subtotal).borders = [ :top ]
      t.row(fila_subtotal).border_color = AZUL_FUYEN
      t.row(fila_total).background_color = AZUL_FUYEN
      t.row(fila_total).text_color = "ffffff"
    end
    doc.move_down 20
  end

  # Dirección/instrucciones a la izquierda y datos de contacto a la derecha,
  # en dos columnas parejas (en vez de todo apilado uno debajo del otro) —
  # se ve más ordenado y aprovecha mejor el ancho de la página, como un
  # documento/factura prolijo en vez de una lista suelta.
  def informacion_adicional(doc)
    ancho_columna = (doc.bounds.width - 24) / 2
    y_inicio = doc.cursor

    doc.bounding_box([ 0, y_inicio ], width: ancho_columna) do
      doc.font_size(11) { doc.text "Dirección de entrega", style: :bold }
      doc.font_size(10) { doc.text @order.direccion_completa }

      if @order.notas.present?
        doc.move_down 8
        doc.font_size(11) { doc.text "Instrucciones de entrega", style: :bold }
        doc.font_size(10) { doc.text @order.notas }
      end
    end

    doc.bounding_box([ ancho_columna + 24, y_inicio ], width: ancho_columna) do
      doc.font_size(11) { doc.text "Datos de contacto", style: :bold }
      doc.font_size(10) do
        doc.text @order.nombre_completo_contacto
        doc.text @order.telefono_contacto
        doc.text @order.email_contacto
      end
    end
  end

  def formato_pesos(monto)
    ActiveSupport::NumberHelper.number_to_currency(monto, unit: "$", separator: ",", delimiter: ".", precision: 0)
  end
end
