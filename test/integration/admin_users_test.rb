require "test_helper"

class AdminUsersTest < ActionDispatch::IntegrationTest
  setup do
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

  test "buscar clientes por nombre" do
    encontrado = crear_cliente(nombre: "Valentina", apellido: "Rojas")
    otro = crear_cliente(nombre: "Marcos", apellido: "Soto")

    get admin_users_path(buscar: "valent")
    assert_response :success
    assert_match encontrado.nombre, response.body
    assert_no_match otro.nombre, response.body
  end

  test "buscar clientes por email" do
    encontrado = crear_cliente(email: "unico-buscable@test.cl")
    otro = crear_cliente

    get admin_users_path(buscar: "unico-buscable")
    assert_response :success
    assert_match encontrado.email, response.body
    assert_no_match otro.email, response.body
  end

  test "resetear la contraseña de un cliente" do
    cliente = crear_cliente(password: "password123")

    patch resetear_password_admin_user_path(cliente)
    assert_redirected_to admin_user_path(cliente)

    nueva_password = flash[:notice][/Nueva contraseña para pasarle al cliente por WhatsApp: (\S+)/, 1]
    assert nueva_password.present?, "el aviso debe incluir la contraseña nueva"
    assert cliente.reload.valid_password?(nueva_password)
    assert_not cliente.valid_password?("password123")
  end
end
