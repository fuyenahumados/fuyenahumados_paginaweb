require "test_helper"

class AdminPedidosTest < ActionDispatch::IntegrationTest
  setup do
    entrar_con_token!
    @admin = crear_admin(password: "password123")
    iniciar_sesion!(@admin)
  end

  test "listar pedidos" do
    pedido = crear_pedido
    get admin_pedidos_path
    assert_response :success
    assert_match pedido.codigo_pedido, response.body
  end

  test "ver el detalle de un pedido" do
    pedido = crear_pedido
    get admin_pedido_path(pedido)
    assert_response :success
    assert_match pedido.codigo_pedido, response.body
  end

  test "avanzar el estado de un pedido sigue el flujo definido" do
    pedido = crear_pedido(estado: :pendiente_pago)

    patch avanzar_estado_admin_pedido_path(pedido)
    assert_equal "pagado", pedido.reload.estado

    patch avanzar_estado_admin_pedido_path(pedido)
    assert_equal "en_preparacion", pedido.reload.estado
  end

  test "un pedido entregado no tiene más estado siguiente" do
    pedido = crear_pedido(estado: :entregado)
    patch avanzar_estado_admin_pedido_path(pedido)
    assert_equal "entregado", pedido.reload.estado
  end

  test "cancelar un pedido" do
    pedido = crear_pedido(estado: :pendiente_pago)
    patch cancelar_admin_pedido_path(pedido)
    assert_equal "cancelado", pedido.reload.estado
  end

  test "no se puede cancelar un pedido ya entregado" do
    pedido = crear_pedido(estado: :entregado)
    patch cancelar_admin_pedido_path(pedido)
    assert_equal "entregado", pedido.reload.estado
  end

  test "exportar excel de despacho filtra por fecha de entrega" do
    viernes = Order.proximo_viernes_habil
    otro_viernes = viernes + 7.days

    crear_pedido(fecha_entrega: viernes, estado: :pagado)
    crear_pedido(fecha_entrega: otro_viernes)

    get exportar_admin_pedidos_path(fecha_despacho: viernes.iso8601)
    assert_response :success
    assert_equal "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", response.media_type
    assert_match(/\.xlsx/, response.headers["Content-Disposition"])
    assert response.body.b.start_with?("PK"), "debe ser un .xlsx válido (firma ZIP)"
  end

  test "exportar excel con fecha inválida redirige con error" do
    get exportar_admin_pedidos_path(fecha_despacho: "no-es-una-fecha")
    assert_redirected_to admin_pedidos_path
  end

  test "filtrar pedidos por fecha de entrega" do
    viernes = Order.proximo_viernes_habil
    otro_viernes = viernes + 7.days

    pedido_de_ese_viernes = crear_pedido(fecha_entrega: viernes)
    pedido_de_otro_viernes = crear_pedido(fecha_entrega: otro_viernes)

    get admin_pedidos_path(fecha: viernes.iso8601)
    assert_response :success
    assert_match pedido_de_ese_viernes.codigo_pedido, response.body
    assert_no_match pedido_de_otro_viernes.codigo_pedido, response.body
  end

  test "filtrar pedidos con fecha inválida redirige con error" do
    get admin_pedidos_path(fecha: "no-es-una-fecha")
    assert_redirected_to admin_pedidos_path
  end

  test "buscar pedidos por código" do
    encontrado = crear_pedido
    otro = crear_pedido

    get admin_pedidos_path(buscar: encontrado.codigo_pedido)
    assert_response :success
    assert_match encontrado.codigo_pedido, response.body
    assert_no_match otro.codigo_pedido, response.body
  end

  test "buscar pedidos de invitado por nombre de contacto" do
    encontrado = crear_pedido(nombre_contacto: "Camila", apellido_contacto: "Vergara")
    otro = crear_pedido(nombre_contacto: "Diego", apellido_contacto: "Muñoz")

    get admin_pedidos_path(buscar: "camila")
    assert_response :success
    assert_match encontrado.codigo_pedido, response.body
    assert_no_match otro.codigo_pedido, response.body
  end

  test "buscar pedidos por nombre del cliente registrado" do
    cliente = crear_cliente(nombre: "Ignacio", apellido: "Bravo")
    encontrado = crear_pedido(usuario: cliente)
    otro = crear_pedido

    get admin_pedidos_path(buscar: "ignacio")
    assert_response :success
    assert_match encontrado.codigo_pedido, response.body
    assert_no_match otro.codigo_pedido, response.body
  end

  test "ver el formulario de nuevo pedido manual" do
    get new_admin_pedido_path
    assert_response :success
  end

  test "crear un pedido manual con cliente nuevo marca source manual y descuenta stock" do
    producto = crear_producto(precio: 5000, stock: 10)

    assert_difference "Order.count", 1 do
      post admin_pedidos_path, params: {
        order: {
          nombre_contacto: "Camila", apellido_contacto: "Vergara",
          telefono_contacto: "+56911111111", email_contacto: "camila@test.cl",
          direccion_calle: "Calle 123", direccion_comuna: "Providencia",
          fecha_entrega: Order.proximo_viernes_habil.iso8601,
          estado: "pagado",
          order_items_attributes: { "0" => { product_id: producto.id, cantidad: 3 } }
        }
      }
    end

    pedido = Order.last
    assert_redirected_to admin_pedido_path(pedido)
    assert_equal "manual", pedido.source
    assert pedido.invitado?
    assert_equal "pagado", pedido.estado
    assert_equal 5000, pedido.order_items.sole.precio_unitario
    assert_equal 7, producto.reload.stock
  end

  test "crear un pedido manual con un cliente existente lo asocia a su cuenta" do
    cliente = crear_cliente(nombre: "Ignacio", apellido: "Bravo")
    producto = crear_producto(stock: 10)

    post admin_pedidos_path, params: {
      order: {
        user_id: cliente.id,
        nombre_contacto: cliente.nombre, apellido_contacto: cliente.apellido,
        telefono_contacto: cliente.telefono, email_contacto: cliente.email,
        direccion_calle: "Calle 456", direccion_comuna: "Las Condes",
        fecha_entrega: Order.proximo_viernes_habil.iso8601,
        order_items_attributes: { "0" => { product_id: producto.id, cantidad: 1 } }
      }
    }

    assert_equal cliente, Order.last.user
  end

  test "un pedido manual acepta una fecha de entrega pasada" do
    producto = crear_producto(stock: 10)
    fecha_pasada = Order.proximo_viernes_habil - 7.days

    post admin_pedidos_path, params: {
      order: {
        nombre_contacto: "Test", apellido_contacto: "Cliente",
        telefono_contacto: "+56911111111", email_contacto: "a@test.cl",
        direccion_calle: "Calle 123", direccion_comuna: "Providencia",
        fecha_entrega: fecha_pasada.iso8601,
        order_items_attributes: { "0" => { product_id: producto.id, cantidad: 1 } }
      }
    }

    assert_equal fecha_pasada, Order.last.fecha_entrega
  end

  test "crear un pedido manual sin productos no guarda el pedido" do
    assert_no_difference "Order.count" do
      post admin_pedidos_path, params: {
        order: {
          nombre_contacto: "Test", apellido_contacto: "Cliente",
          telefono_contacto: "+56911111111", email_contacto: "a@test.cl",
          direccion_calle: "Calle 123", direccion_comuna: "Providencia",
          fecha_entrega: Order.proximo_viernes_habil.iso8601
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "crear un pedido manual con más cantidad que el stock disponible falla" do
    producto = crear_producto(stock: 2)

    assert_no_difference "Order.count" do
      post admin_pedidos_path, params: {
        order: {
          nombre_contacto: "Test", apellido_contacto: "Cliente",
          telefono_contacto: "+56911111111", email_contacto: "a@test.cl",
          direccion_calle: "Calle 123", direccion_comuna: "Providencia",
          fecha_entrega: Order.proximo_viernes_habil.iso8601,
          order_items_attributes: { "0" => { product_id: producto.id, cantidad: 5 } }
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "el listado marca con un badge solo los pedidos manuales" do
    producto = crear_producto(stock: 10)
    post admin_pedidos_path, params: {
      order: {
        nombre_contacto: "Test", apellido_contacto: "Cliente",
        telefono_contacto: "+56911111111", email_contacto: "a@test.cl",
        direccion_calle: "Calle 123", direccion_comuna: "Providencia",
        fecha_entrega: Order.proximo_viernes_habil.iso8601,
        order_items_attributes: { "0" => { product_id: producto.id, cantidad: 1 } }
      }
    }
    crear_pedido

    get admin_pedidos_path
    assert_equal 1, response.body.scan("badge-manual").size
  end
end
