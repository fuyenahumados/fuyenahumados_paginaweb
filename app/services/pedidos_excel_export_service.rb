# Genera el Excel de los pedidos de una fecha de entrega puntual (un viernes de
# despacho), no solo los pagados, para que el negocio vea de un vistazo lo que
# hay que preparar ese día, con una columna de estado para distinguir qué está
# pagado y qué no. Se genera al vuelo desde el panel admin (send_data) — Render
# tiene filesystem efímero, no se guarda en disco.
#
# Cada pedido ocupa una fila por producto (en vez de todo junto en una sola
# celda) para que no se mezclen las cantidades cuando alguien pidió varias
# cosas — las columnas que son del pedido completo (código, cliente, etc.) se
# combinan en una sola celda que abarca esas filas. El fondo alterna gris
# clarito/sin color pedido por medio (no fila por fila) para que se note de
# un vistazo dónde termina un cliente y empieza el siguiente. Los pedidos van
# ordenados por comuna (no por fecha de creación) para planificar el
# despacho más fácil.
#
# La fila 1 queda vacía y la columna A queda angosta pero visible (no oculta)
# a propósito — la tabla principal arranca recién en B2, como un margen/marco
# alrededor. Al lado (separadas por columnas angostas también fijas, mismo
# criterio que la A) van dos tablas de resumen: cantidad total por producto,
# y cuántos pedidos hay que despachar en cada comuna.
class PedidosExcelExportService
  MESES_ES = %w[
    enero febrero marzo abril mayo junio julio
    agosto septiembre octubre noviembre diciembre
  ].freeze

  COLOR_ENCABEZADO_FONDO = "2E7D32" # mismo verde que .envio-gratis del sitio
  COLOR_ENCABEZADO_TEXTO = "FFFFFF"
  COLOR_FILA_ALTERNA     = "F2F2F2"
  COLOR_BORDE            = "999999"

  ENCABEZADOS = [
    "Código", "Cliente", "Teléfono", "Dirección", "Comuna", "Instrucciones de entrega",
    "Producto", "Cantidad", "Subtotal productos", "Envío", "Total", "Estado"
  ].freeze

  # Índices de columna (0 = A). La tabla principal ocupa A(vacía)..M (13
  # columnas, índices 0-12). Cada tabla de resumen va separada por una
  # columna angosta de por medio, igual que la A.
  COLUMNA_GAP_RESUMEN_PRODUCTO = 13 # N
  COLUMNA_RESUMEN_PRODUCTO     = 14 # O
  COLUMNA_RESUMEN_CANTIDAD     = 15 # P
  COLUMNA_GAP_RESUMEN_COMUNA   = 16 # Q
  COLUMNA_RESUMEN_COMUNA       = 17 # R
  COLUMNA_RESUMEN_COMUNA_CANTIDAD = 18 # S

  ANCHO_COLUMNA_ANGOSTA = 3

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
                    .order(:direccion_comuna, created_at: :asc)
                    .to_a

    package = Axlsx::Package.new

    package.workbook.add_worksheet(name: nombre_hoja) do |sheet|
      estilos = construir_estilos(sheet)
      anchos = Array.new(COLUMNA_RESUMEN_COMUNA_CANTIDAD + 1)
      anchos[0] = ANCHO_COLUMNA_ANGOSTA
      anchos[COLUMNA_GAP_RESUMEN_PRODUCTO] = ANCHO_COLUMNA_ANGOSTA
      anchos[COLUMNA_GAP_RESUMEN_COMUNA] = ANCHO_COLUMNA_ANGOSTA
      sheet.column_widths(*anchos)

      principal, merges = construir_filas_principal(pedidos, estilos)
      resumen_productos = construir_filas_resumen_productos(pedidos, estilos)
      resumen_comunas = construir_filas_resumen_comunas(pedidos, estilos)

      combinar_y_escribir(sheet, principal, resumen_productos, resumen_comunas)
      merges.each { |rango| sheet.merge_cells(rango) }

      letra_producto_a = Axlsx.col_ref(COLUMNA_RESUMEN_PRODUCTO)
      letra_producto_b = Axlsx.col_ref(COLUMNA_RESUMEN_CANTIDAD)
      sheet.merge_cells("#{letra_producto_a}2:#{letra_producto_b}2")

      letra_comuna_a = Axlsx.col_ref(COLUMNA_RESUMEN_COMUNA)
      letra_comuna_b = Axlsx.col_ref(COLUMNA_RESUMEN_COMUNA_CANTIDAD)
      sheet.merge_cells("#{letra_comuna_a}2:#{letra_comuna_b}2")
    end

    package.to_stream.read
  end

  private

  def construir_estilos(sheet)
    borde = { style: :thin, color: COLOR_BORDE }

    {
      encabezado: sheet.styles.add_style(
        bg_color: COLOR_ENCABEZADO_FONDO, fg_color: COLOR_ENCABEZADO_TEXTO, b: true,
        alignment: { horizontal: :center, vertical: :center }, border: borde
      ),
      resaltado: sheet.styles.add_style(
        bg_color: COLOR_ENCABEZADO_FONDO, fg_color: COLOR_ENCABEZADO_TEXTO, b: true,
        format_code: "#,##0", alignment: { vertical: :center }, border: borde
      ),
      texto: { true => sheet.styles.add_style(bg_color: COLOR_FILA_ALTERNA, alignment: { vertical: :center }, border: borde),
                false => sheet.styles.add_style(alignment: { vertical: :center }, border: borde) },
      moneda: { true => sheet.styles.add_style(bg_color: COLOR_FILA_ALTERNA, format_code: "#,##0", alignment: { vertical: :center }, border: borde),
                 false => sheet.styles.add_style(format_code: "#,##0", alignment: { vertical: :center }, border: borde) }
    }
  end

  # Devuelve un array de filas ({valores:, estilos:}) alineado 1:1 con las
  # filas reales de la hoja (índice 0 = fila 1, la que queda vacía). Cada
  # fila arranca con un `nil` extra para la columna A (vacía a propósito).
  # `merges` son rangos ("B3:B4") para combinar verticalmente las columnas
  # del pedido completo cuando ocupa más de una fila (varios productos).
  def construir_filas_principal(pedidos, estilos)
    filas = []
    merges = []

    filas[0] = { valores: [], estilos: [] } # fila 1 vacía
    filas[1] = { valores: [ nil, *ENCABEZADOS ], estilos: [ nil, *Array.new(ENCABEZADOS.size, estilos[:encabezado]) ] }

    fila_idx = 2
    pedidos.each_with_index do |pedido, indice|
      fila_alterna = indice.even?
      fila_inicio = fila_idx
      direccion_sin_comuna = [ pedido.direccion_calle, pedido.direccion_numero_depto ].reject(&:blank?).join(", ")

      pedido.order_items.each do |item|
        filas[fila_idx] = {
          valores: [
            nil,
            pedido.codigo_pedido,
            pedido.nombre_completo_contacto,
            pedido.telefono_contacto,
            direccion_sin_comuna,
            pedido.direccion_comuna,
            pedido.notas,
            "#{item.product.nombre} (#{item.product.peso_descripcion})",
            item.cantidad,
            pedido.subtotal_productos.to_f,
            pedido.envio.to_f,
            pedido.total.to_f,
            ApplicationHelper::ESTADO_LABELS.fetch(pedido.estado, pedido.estado)
          ],
          estilos: fila_estilos(estilos, fila_alterna)
        }
        fila_idx += 1
      end

      fila_fin = fila_idx - 1
      if fila_fin > fila_inicio
        [ 1, 2, 3, 4, 5, 6, 9, 10, 11, 12 ].each do |columna|
          letra = Axlsx.col_ref(columna)
          merges << "#{letra}#{fila_inicio + 1}:#{letra}#{fila_fin + 1}" # +1: índice de array -> número de fila real
        end
      end
    end

    [ filas, merges ]
  end

  # style: columna A (vacía, sin estilo) y luego una por columna, en el mismo
  # orden que ENCABEZADOS.
  def fila_estilos(estilos, fila_alterna)
    [
      nil,
      estilos[:texto][fila_alterna], estilos[:texto][fila_alterna], estilos[:texto][fila_alterna],
      estilos[:texto][fila_alterna], estilos[:texto][fila_alterna], estilos[:texto][fila_alterna],
      estilos[:texto][fila_alterna], estilos[:texto][fila_alterna],
      estilos[:moneda][fila_alterna], estilos[:moneda][fila_alterna], estilos[:moneda][fila_alterna],
      estilos[:texto][fila_alterna]
    ]
  end

  # Misma alineación por índice de fila que construir_filas_principal (índice
  # 0 = fila 1, vacía) para que combinar_y_escribir pueda pegar las tres
  # tablas fila a fila sin desalinearlas.
  def construir_filas_resumen_productos(pedidos, estilos)
    cantidad_por_producto = Hash.new(0)
    pedidos.each do |pedido|
      pedido.order_items.each do |item|
        clave = "#{item.product.nombre} (#{item.product.peso_descripcion})"
        cantidad_por_producto[clave] += item.cantidad
      end
    end

    filas = []
    filas[0] = { valores: [], estilos: [] } # fila 1 vacía, igual que la tabla principal
    filas[1] = { valores: [ "Resumen por producto", nil ], estilos: [ estilos[:encabezado], estilos[:encabezado] ] }
    filas[2] = { valores: [ "Producto", "Cantidad" ], estilos: [ estilos[:encabezado], estilos[:encabezado] ] }

    fila_idx = 3
    cantidad_por_producto.sort.each do |producto, cantidad|
      filas[fila_idx] = { valores: [ producto, cantidad ], estilos: [ estilos[:texto][false], estilos[:moneda][false] ] }
      fila_idx += 1
    end

    fila_idx += 1 # fila en blanco antes de los totales generales
    filas[fila_idx] = { valores: [ "Pedidos", pedidos.size ], estilos: [ estilos[:texto][false], estilos[:moneda][false] ] }
    fila_idx += 1
    filas[fila_idx] = { valores: [ "Artículos totales", cantidad_por_producto.values.sum ], estilos: [ estilos[:texto][false], estilos[:moneda][false] ] }
    fila_idx += 1
    filas[fila_idx] = { valores: [ "Monto total", pedidos.sum(&:total).to_f ], estilos: [ estilos[:resaltado], estilos[:resaltado] ] }

    filas
  end

  # Cuenta pedidos (no artículos) por comuna, para saber cuántas paradas hay
  # que hacer en cada una a la hora de armar la ruta de despacho.
  def construir_filas_resumen_comunas(pedidos, estilos)
    pedidos_por_comuna = pedidos.group_by(&:direccion_comuna).transform_values(&:size)

    filas = []
    filas[0] = { valores: [], estilos: [] }
    filas[1] = { valores: [ "Despacho por comuna", nil ], estilos: [ estilos[:encabezado], estilos[:encabezado] ] }
    filas[2] = { valores: [ "Comuna", "Pedidos" ], estilos: [ estilos[:encabezado], estilos[:encabezado] ] }

    fila_idx = 3
    pedidos_por_comuna.sort.each do |comuna, cantidad|
      filas[fila_idx] = { valores: [ comuna, cantidad ], estilos: [ estilos[:texto][false], estilos[:moneda][false] ] }
      fila_idx += 1
    end

    filas
  end

  # Pega las tres tablas fila a fila (con columnas angostas de por medio en
  # blanco) y recién ahí las escribe en la hoja — así quedan alineadas por
  # fila sin importar que tengan largos distintos.
  #
  # Cuando una tabla de resumen tiene más filas que la principal (algo muy
  # común: los resúmenes suman filas fijas de totales al final), a esas
  # filas les falta el lado izquierdo — hay que rellenarlas con el ANCHO
  # completo de la tabla que falta para que lo de más a la derecha no se
  # corra a columnas equivocadas. Un array vacío ahí correría todo lo
  # siguiente hacia la izquierda.
  def combinar_y_escribir(sheet, principal, resumen_productos, resumen_comunas)
    total_filas = [ principal.size, resumen_productos.size, resumen_comunas.size ].max
    ancho_principal = ENCABEZADOS.size + 1 # +1 por la columna A
    ancho_resumen_productos = 2
    fila_principal_vacia = { valores: Array.new(ancho_principal), estilos: Array.new(ancho_principal) }
    fila_resumen_productos_vacia = { valores: Array.new(ancho_resumen_productos), estilos: Array.new(ancho_resumen_productos) }
    fila_resumen_comunas_vacia = { valores: [], estilos: [] }

    (0...total_filas).each do |i|
      p = principal[i] || fila_principal_vacia
      rp = resumen_productos[i] || fila_resumen_productos_vacia
      rc = resumen_comunas[i] || fila_resumen_comunas_vacia

      sheet.add_row(
        p[:valores] + [ nil ] + rp[:valores] + [ nil ] + rc[:valores],
        style: p[:estilos] + [ nil ] + rp[:estilos] + [ nil ] + rc[:estilos]
      )
    end
  end

  def nombre_hoja
    "Pedido_#{fecha_formateada}"[0, 31]
  end

  def fecha_formateada
    "#{@fecha_despacho.day}_de_#{MESES_ES[@fecha_despacho.month - 1]}"
  end
end
