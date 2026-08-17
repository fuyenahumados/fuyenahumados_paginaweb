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
end
