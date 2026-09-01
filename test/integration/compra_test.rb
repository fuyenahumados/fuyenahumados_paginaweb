require "test_helper"

class CompraTest < ActionDispatch::IntegrationTest
  setup do
    @producto = crear_producto(nombre: "Salmón pieza chica", precio: 4500, stock: 10)
  end

  test "el catálogo lista solo productos disponibles" do
    activo = @producto
    inactivo = crear_producto(activo: false)
    sin_stock = crear_producto(stock: 0)

    get productos_path
    assert_response :success
    assert_match activo.nombre, response.body
    assert_no_match inactivo.nombre, response.body
    assert_no_match sin_stock.nombre, response.body
  end

  test "el catálogo se puede filtrar por rango de precio y ordenar" do
    barato = crear_producto(nombre: "Barato", precio: 3000)
    caro = crear_producto(nombre: "Caro", precio: 25_000)

    get productos_path(precio_rango: "19990-")
    assert_match caro.nombre, response.body
    assert_no_match barato.nombre, response.body

    get productos_path(orden: "precio_desc")
    assert_response :success
  end

  test "la ficha de un producto se puede ver" do
    get producto_path(@producto)
    assert_response :success
    assert_match @producto.nombre, response.body
  end

  test "agregar al carrito y verlo reflejado en /carrito" do
    post agregar_carrito_path, params: { product_id: @producto.id, cantidad: 2, contexto: "detalle" }
    assert_redirected_to carrito_path

    get carrito_path
    assert_match @producto.nombre, response.body
    assert_match "9.000", response.body.gsub("&nbsp;", " ") # 2 x 4.500 = 9.000 subtotal
  end

  test "agregar respeta el stock disponible como tope" do
    post agregar_carrito_path, params: { product_id: @producto.id, cantidad: 999 }
    get carrito_path
    assert_match(/\b#{@producto.stock}\b/, response.body)
  end

  test "actualizar cantidad y quitar del carrito" do
    post agregar_carrito_path, params: { product_id: @producto.id, cantidad: 1 }

    patch actualizar_carrito_path, params: { product_id: @producto.id, cantidad: 3 }
    assert_redirected_to carrito_path

    delete quitar_carrito_path, params: { product_id: @producto.id }
    get carrito_path
    assert_no_match @producto.nombre, response.body
  end

  test "agregar/actualizar con un producto inexistente redirige con error" do
    post agregar_carrito_path, params: { product_id: 0, cantidad: 1 }
    assert_redirected_to root_path

    patch actualizar_carrito_path, params: { product_id: 0, cantidad: 1 }
    assert_redirected_to root_path
  end

  test "agregar al carrito vía turbo-stream desde la ficha de producto (modal)" do
    post agregar_carrito_path,
      params: { product_id: @producto.id, cantidad: 1, contexto: "detalle" },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match "modal-carrito", response.body
  end

  test "agregar al carrito vía turbo-stream desde el catálogo (sin modal)" do
    post agregar_carrito_path,
      params: { product_id: @producto.id, cantidad: 1, contexto: "catalogo" },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match "producto-accion-#{@producto.id}", response.body
  end

  test "actualizar cantidad a cero vía turbo-stream la quita del carrito" do
    post agregar_carrito_path, params: { product_id: @producto.id, cantidad: 1 }

    patch actualizar_carrito_path,
      params: { product_id: @producto.id, cantidad: 0, origen: "carrito" },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success

    get carrito_path
    assert_match "Tu carrito está vacío", response.body
  end

  test "actualizar desde el catálogo (no desde el carrito) vía turbo-stream" do
    post agregar_carrito_path, params: { product_id: @producto.id, cantidad: 1 }

    patch actualizar_carrito_path,
      params: { product_id: @producto.id, cantidad: 2, origen: "catalogo" },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match "producto-accion-#{@producto.id}", response.body
  end

  test "quitar del carrito vía turbo-stream" do
    post agregar_carrito_path, params: { product_id: @producto.id, cantidad: 1 }

    delete quitar_carrito_path,
      params: { product_id: @producto.id },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
  end

  test "el checkout redirige al carrito si está vacío" do
    get checkout_path
    assert_redirected_to root_path
  end

  test "flujo completo de compra como cliente logueado" do
    cliente = crear_cliente(password: "password123")
    crear_direccion(cliente, etiqueta: "Casa", comuna: "Providencia", calle: "Av. Siempre Viva 123")
    iniciar_sesion!(cliente)

    post agregar_carrito_path, params: { product_id: @producto.id, cantidad: 2 }

    get checkout_path
    assert_response :success
    assert_match "Av. Siempre Viva 123", response.body

    viernes = Order.proximo_viernes_habil
    resultado_ok = GeocodificadorService::Resultado.new(encontrada: true, lat: -33.4, lng: -70.6)

    assert_difference "Order.count", 1 do
      stub_geocodificador(resultado_ok) do
        post checkout_path, params: {
          order: {
            nombre_contacto: cliente.nombre, apellido_contacto: cliente.apellido,
            telefono_contacto: cliente.telefono, email_contacto: cliente.email,
            direccion_calle: "Av. Siempre Viva 123", direccion_numero_depto: "Depto 1", direccion_comuna: "Providencia",
            fecha_entrega: viernes.iso8601
          }
        }
      end
    end

    pedido = cliente.orders.last
    assert_redirected_to pedido_publico_path(pedido.codigo_pedido)
    assert_equal 2, pedido.order_items.sole.cantidad
    assert_equal 9000, pedido.subtotal_productos
    assert_equal "pendiente_pago", pedido.estado

    assert_equal 8, @producto.reload.stock # 10 - 2

    follow_redirect!
    assert_response :success
    assert_match pedido.codigo_pedido, response.body
    assert_match "Confirmar pedido por WhatsApp", response.body
  end

  test "un invitado sin cuenta también puede comprar" do
    post agregar_carrito_path, params: { product_id: @producto.id, cantidad: 1 }

    viernes = Order.proximo_viernes_habil
    resultado_ok = GeocodificadorService::Resultado.new(encontrada: true, lat: -33.4, lng: -70.6)

    assert_difference "Order.count", 1 do
      stub_geocodificador(resultado_ok) do
        post checkout_path, params: {
          order: {
            nombre_contacto: "Invitado", apellido_contacto: "DePrueba",
            telefono_contacto: "+56933334444", email_contacto: "invitado@test.cl",
            direccion_calle: "Calle Invitado 1", direccion_numero_depto: "Depto 1", direccion_comuna: "Las Condes",
            fecha_entrega: viernes.iso8601
          }
        }
      end
    end

    pedido = Order.last
    assert_nil pedido.user
    assert pedido.invitado?
  end

  test "no se puede confirmar el checkout con una fecha de entrega inválida" do
    post agregar_carrito_path, params: { product_id: @producto.id, cantidad: 1 }

    assert_no_difference "Order.count" do
      post checkout_path, params: {
        order: {
          nombre_contacto: "Test", apellido_contacto: "Cliente",
          telefono_contacto: "+56911111111", email_contacto: "a@test.cl",
          direccion_calle: "Calle 1", direccion_numero_depto: "Depto 1", direccion_comuna: "Providencia",
          fecha_entrega: (Order.proximo_viernes_habil + 1.day).iso8601 # sábado
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "una dirección que Nominatim no encuentra no bloquea el pedido, solo no le guarda lat/lng" do
    post agregar_carrito_path, params: { product_id: @producto.id, cantidad: 1 }
    resultado_no_encontrada = GeocodificadorService::Resultado.new(encontrada: false)

    assert_difference "Order.count", 1 do
      stub_geocodificador(resultado_no_encontrada) do
        post checkout_path, params: {
          order: {
            nombre_contacto: "Test", apellido_contacto: "Cliente",
            telefono_contacto: "+56911111111", email_contacto: "a@test.cl",
            direccion_calle: "Calle que no existe 99999", direccion_numero_depto: "Depto 1", direccion_comuna: "Providencia",
            fecha_entrega: Order.proximo_viernes_habil.iso8601
          }
        }
      end
    end
    assert_nil Order.last.lat
  end

  test "si el servicio de geocodificación no responde, el pedido igual se confirma" do
    post agregar_carrito_path, params: { product_id: @producto.id, cantidad: 1 }

    assert_difference "Order.count", 1 do
      stub_geocodificador(nil) do
        post checkout_path, params: {
          order: {
            nombre_contacto: "Test", apellido_contacto: "Cliente",
            telefono_contacto: "+56911111111", email_contacto: "a@test.cl",
            direccion_calle: "Calle 1", direccion_numero_depto: "Depto 1", direccion_comuna: "Providencia",
            fecha_entrega: Order.proximo_viernes_habil.iso8601
          }
        }
      end
    end
    assert_nil Order.last.lat
  end

  test "una dirección que Nominatim sí encuentra guarda lat/lng en el pedido" do
    post agregar_carrito_path, params: { product_id: @producto.id, cantidad: 1 }
    resultado_ok = GeocodificadorService::Resultado.new(encontrada: true, lat: -33.4, lng: -70.6)

    stub_geocodificador(resultado_ok) do
      post checkout_path, params: {
        order: {
          nombre_contacto: "Test", apellido_contacto: "Cliente",
          telefono_contacto: "+56911111111", email_contacto: "a@test.cl",
          direccion_calle: "Calle 1", direccion_numero_depto: "Depto 1", direccion_comuna: "Providencia",
          fecha_entrega: Order.proximo_viernes_habil.iso8601
        }
      }
    end
    assert_equal(-33.4, Order.last.lat)
  end

  test "consultar un pedido por código sin sesión de usuario" do
    pedido = crear_pedido

    get nuevo_pedido_publico_path
    assert_response :success

    post buscar_pedido_publico_path, params: { codigo_pedido: pedido.codigo_pedido }
    assert_redirected_to pedido_publico_path(pedido.codigo_pedido)
  end

  test "buscar un pedido con un código que no existe redirige con error" do
    post buscar_pedido_publico_path, params: { codigo_pedido: "FUY-000000" }
    assert_redirected_to nuevo_pedido_publico_path
    assert_equal "No encontramos ningún pedido con ese código.", flash[:alert]
  end

  test "ver un pedido con un código inexistente en la URL redirige con error" do
    get pedido_publico_path("FUY-000000")
    assert_redirected_to nuevo_pedido_publico_path
  end

  test "descargar el pedido devuelve un PDF" do
    pedido = crear_pedido

    get descargar_pedido_publico_path(pedido.codigo_pedido)
    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert_equal "%PDF".b, response.body.b[0, 4]
  end

  test "descargar un pedido con un código inexistente redirige con error" do
    get descargar_pedido_publico_path("FUY-000000")
    assert_redirected_to nuevo_pedido_publico_path
  end

  test "el catálogo se puede buscar por texto en nombre o descripción" do
    ahumado = crear_producto(nombre: "Salmón ahumado premium", descripcion: "El mejor del sur")
    otro = crear_producto(nombre: "Trucha", descripcion: "Otra cosa")

    get productos_path(buscar: "ahumado")
    assert_match ahumado.nombre, response.body
    assert_no_match otro.nombre, response.body

    get productos_path(buscar: "sur")
    assert_match ahumado.nombre, response.body
  end

  test "una búsqueda sin resultados muestra el estado vacío" do
    get productos_path(buscar: "algo-que-no-existe-nunca")
    assert_match "No hay productos que coincidan", response.body
  end

  test "el catálogo se puede filtrar por categoría" do
    get productos_path(categoria: "ahumado")
    assert_response :success
  end
end
