require "test_helper"

class OrderTest < ActiveSupport::TestCase
  def viernes_valido
    Order.proximo_viernes_habil
  end

  test "genera automáticamente un código de pedido con el formato esperado" do
    pedido = crear_pedido
    assert_match(/\AFUY-[0-9A-F]{6}\z/, pedido.codigo_pedido)
  end

  test "el código de pedido es único" do
    uno = crear_pedido
    otro = crear_pedido
    assert_not_equal uno.codigo_pedido, otro.codigo_pedido
  end

  test "requiere nombre_contacto, apellido_contacto y direccion_calle" do
    usuario = crear_cliente
    pedido = Order.new(
      user: usuario, nombre_contacto: nil, apellido_contacto: nil,
      direccion_calle: nil, direccion_numero_depto: nil, direccion_comuna: "Providencia",
      telefono_contacto: "+56911111111", email_contacto: "a@test.cl",
      fecha_entrega: viernes_valido, total: 0
    )
    assert_not pedido.valid?
    assert_includes pedido.errors[:nombre_contacto], "no puede estar en blanco"
    assert_includes pedido.errors[:apellido_contacto], "no puede estar en blanco"
    assert_includes pedido.errors[:direccion_calle], "no puede estar en blanco"
  end

  test "direccion_numero_depto es opcional" do
    pedido = crear_pedido(direccion_numero_depto: nil)
    assert pedido.valid?
  end

  test "direccion_completa arma la dirección saltándose el numero_depto si está vacío" do
    pedido = crear_pedido(direccion_calle: "Cerro de Ramón 12334", direccion_numero_depto: nil, direccion_comuna: "La Reina")
    assert_equal "Cerro de Ramón 12334, La Reina", pedido.direccion_completa

    pedido.direccion_numero_depto = "Casa 8"
    assert_equal "Cerro de Ramón 12334, Casa 8, La Reina", pedido.direccion_completa
  end

  test "la comuna debe estar en la lista fija" do
    pedido = crear_pedido
    pedido.direccion_comuna = "Santiago Centro"
    assert_not pedido.valid?
  end

  test "el teléfono y el email deben tener formato válido" do
    pedido = crear_pedido
    pedido.telefono_contacto = "abc"
    assert_not pedido.valid?

    pedido.telefono_contacto = "+56911111111"
    pedido.email_contacto = "no-es-un-email"
    assert_not pedido.valid?
  end

  test "total y envio no pueden ser negativos" do
    pedido = crear_pedido
    pedido.total = -1
    assert_not pedido.valid?

    pedido.total = 0
    pedido.envio = -1
    assert_not pedido.valid?
  end

  test "fecha_entrega es obligatoria y debe ser viernes" do
    pedido = crear_pedido
    pedido.fecha_entrega = nil
    assert_not pedido.valid?

    pedido.fecha_entrega = viernes_valido + 1.day # sábado
    assert_not pedido.valid?
    assert_includes pedido.errors[:fecha_entrega], "debe ser un día viernes (los despachos son solo los viernes)"
  end

  test "fecha_entrega no puede ser anterior al próximo viernes hábil al crear" do
    pedido = Order.new(
      user: nil, nombre_contacto: "Test", apellido_contacto: "Cliente",
      telefono_contacto: "+56911111111", email_contacto: "a@test.cl",
      direccion_calle: "Calle 123", direccion_numero_depto: "Depto 1", direccion_comuna: "Providencia",
      fecha_entrega: viernes_valido - 7.days, total: 0
    )
    assert_not pedido.valid?
    assert pedido.errors[:fecha_entrega].any? { |m| m.include?("debe ser el") }
  end

  test "esa regla de fecha mínima no se reaplica al actualizar un pedido existente" do
    pedido = crear_pedido(fecha_entrega: viernes_valido)
    travel_to(pedido.fecha_entrega + 1.day) do
      pedido.reload
      assert pedido.valid?, "un pedido viejo no debería invalidarse solo por el paso del tiempo"
    end
  end

  test "proximo_viernes_habil nunca devuelve el mismo día, ni si hoy es viernes" do
    un_lunes = Date.parse("2026-08-17")
    assert_equal Date.parse("2026-08-21"), Order.proximo_viernes_habil(desde: un_lunes)

    un_viernes = Date.parse("2026-08-21")
    assert_equal Date.parse("2026-08-28"), Order.proximo_viernes_habil(desde: un_viernes)
  end

  test "subtotal_productos suma cantidad por precio_unitario de los items" do
    pedido = crear_pedido
    producto = crear_producto(precio: 2000)
    pedido.order_items.create!(product: producto, cantidad: 3, precio_unitario: 2000)

    assert_equal pedido.order_items.sum { |i| i.cantidad * i.precio_unitario }, pedido.subtotal_productos
  end

  test "calcular_total setea envio y total según CostoEnvio" do
    barato = crear_producto(precio: 1000)
    pedido = Order.new(
      nombre_contacto: "Test", apellido_contacto: "Cliente", telefono_contacto: "+56911111111",
      email_contacto: "a@test.cl", direccion_calle: "Calle 123", direccion_numero_depto: "Depto 1", direccion_comuna: "Providencia",
      fecha_entrega: viernes_valido, total: 0
    )
    pedido.save!
    pedido.order_items.create!(product: barato, cantidad: 1, precio_unitario: 1000)

    pedido.calcular_total

    assert_equal 1000, pedido.subtotal_productos
    assert_equal CostoEnvio::MONTO, pedido.envio
    assert_equal 1000 + CostoEnvio::MONTO, pedido.total
  end

  test "calcular_total da envio gratis sobre el umbral" do
    caro = crear_producto(precio: CostoEnvio::GRATIS_DESDE)
    pedido = crear_pedido(productos: caro)
    pedido.calcular_total

    assert_equal 0, pedido.envio
    assert_equal CostoEnvio::GRATIS_DESDE, pedido.total
  end

  test "nombre_completo_contacto concatena nombre y apellido de contacto" do
    pedido = crear_pedido(nombre_contacto: "Ana", apellido_contacto: "Pérez")
    assert_equal "Ana Pérez", pedido.nombre_completo_contacto
  end

  test "invitado? es true cuando el pedido no tiene usuario" do
    con_usuario = crear_pedido(usuario: crear_cliente)
    sin_usuario = crear_pedido

    assert_not con_usuario.invitado?
    assert sin_usuario.invitado?
  end

  test "registra un cambio de historial al crear el pedido" do
    pedido = crear_pedido
    assert_equal 1, pedido.order_status_changes.count
    assert_equal "pendiente_pago", pedido.order_status_changes.first.estado
  end

  test "registra un nuevo cambio de historial cada vez que cambia el estado" do
    pedido = crear_pedido
    pedido.update!(estado: :pagado)
    pedido.update!(estado: :en_preparacion)

    estados = pedido.order_status_changes.order(:created_at).pluck(:estado)
    assert_equal %w[pendiente_pago pagado en_preparacion], estados
  end

  test "actualizar un pedido sin cambiar el estado no agrega historial" do
    pedido = crear_pedido
    assert_no_difference "pedido.order_status_changes.count" do
      pedido.update!(notas: "actualización sin cambiar estado")
    end
  end

  test "source por defecto es 'web'" do
    pedido = crear_pedido
    assert_equal "web", pedido.source
    assert_not pedido.manual?
  end

  test "un pedido manual puede tener fecha de entrega anterior al próximo viernes hábil" do
    producto = crear_producto(stock: 5)
    pedido = Order.new(
      source: "manual", nombre_contacto: "Test", apellido_contacto: "Cliente",
      telefono_contacto: "+56911111111", email_contacto: "a@test.cl",
      direccion_calle: "Calle 123", direccion_comuna: "Providencia",
      fecha_entrega: viernes_valido - 7.days, total: 0
    )
    pedido.order_items.build(product: producto, cantidad: 1, precio_unitario: producto.precio)

    assert pedido.valid?
  end

  test "un pedido web no puede tener fecha de entrega anterior al próximo viernes hábil, aunque tenga productos" do
    producto = crear_producto(stock: 5)
    pedido = Order.new(
      nombre_contacto: "Test", apellido_contacto: "Cliente",
      telefono_contacto: "+56911111111", email_contacto: "a@test.cl",
      direccion_calle: "Calle 123", direccion_comuna: "Providencia",
      fecha_entrega: viernes_valido - 7.days, total: 0
    )
    pedido.order_items.build(product: producto, cantidad: 1, precio_unitario: producto.precio)

    assert_not pedido.valid?
  end

  test "un pedido manual requiere al menos un producto" do
    pedido = Order.new(
      source: "manual", nombre_contacto: "Test", apellido_contacto: "Cliente",
      telefono_contacto: "+56911111111", email_contacto: "a@test.cl",
      direccion_calle: "Calle 123", direccion_comuna: "Providencia",
      fecha_entrega: viernes_valido, total: 0
    )

    assert_not pedido.valid?
    assert_includes pedido.errors[:base], "Agrega al menos un producto."
  end

  test "un pedido manual valida que haya stock suficiente por producto" do
    producto = crear_producto(stock: 2)
    pedido = Order.new(
      source: "manual", nombre_contacto: "Test", apellido_contacto: "Cliente",
      telefono_contacto: "+56911111111", email_contacto: "a@test.cl",
      direccion_calle: "Calle 123", direccion_comuna: "Providencia",
      fecha_entrega: viernes_valido, total: 0
    )
    pedido.order_items.build(product: producto, cantidad: 5, precio_unitario: producto.precio)

    assert_not pedido.valid?
    assert pedido.errors[:base].any? { |m| m.include?("quedan 2 unidades") }
  end

  test "un pedido web no exige productos al validar (se agregan después, en el checkout)" do
    pedido = Order.new(
      nombre_contacto: "Test", apellido_contacto: "Cliente",
      telefono_contacto: "+56911111111", email_contacto: "a@test.cl",
      direccion_calle: "Calle 123", direccion_comuna: "Providencia",
      fecha_entrega: viernes_valido, total: 0
    )
    assert pedido.valid?
  end
end
