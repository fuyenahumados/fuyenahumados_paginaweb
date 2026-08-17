require "test_helper"

class AdminUsersTest < ActionDispatch::IntegrationTest
  setup do
    entrar_con_token!
    @admin = crear_admin(password: "password123")
    iniciar_sesion!(@admin)
  end

  test "listar clientes" do
    cliente = crear_cliente
    get admin_users_path
    assert_response :success
    assert_match cliente.nombre, response.body
  end

  test "ver el detalle de un cliente con su historial de pedidos" do
    cliente = crear_cliente
    pedido = crear_pedido(usuario: cliente)

    get admin_user_path(cliente)
    assert_response :success
    assert_match pedido.codigo_pedido, response.body
  end

  test "eliminar un cliente sin pedidos" do
    cliente = crear_cliente
    assert_difference "User.count", -1 do
      delete admin_user_path(cliente)
    end
    assert_redirected_to admin_users_path
  end

  test "no se puede eliminar un cliente con pedidos" do
    cliente = crear_cliente
    crear_pedido(usuario: cliente)

    assert_no_difference "User.count" do
      delete admin_user_path(cliente)
    end
    assert_redirected_to admin_user_path(cliente)
  end
end
