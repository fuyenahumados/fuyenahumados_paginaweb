require "test_helper"

class PerfilDireccionesTest < ActionDispatch::IntegrationTest
  setup do
    entrar_con_token!
    @cliente = crear_cliente(password: "password123")
    crear_direccion(@cliente, etiqueta: "Casa")
    iniciar_sesion!(@cliente)
  end

  test "el perfil muestra los datos y el historial de pedidos del cliente" do
    pedido = crear_pedido(usuario: @cliente)

    get perfil_path
    assert_response :success
    assert_match @cliente.nombre, response.body
    assert_match pedido.codigo_pedido, response.body
  end

  test "editar los datos propios" do
    patch perfil_path, params: { user: { nombre: "Nuevo Nombre", apellido: @cliente.apellido, telefono: @cliente.telefono } }
    assert_redirected_to perfil_path
    assert_equal "Nuevo Nombre", @cliente.reload.nombre
  end

  test "no se puede dejar el teléfono con formato inválido" do
    patch perfil_path, params: { user: { nombre: @cliente.nombre, apellido: @cliente.apellido, telefono: "abc" } }
    assert_response :unprocessable_entity
    assert_equal "+56911111111", @cliente.reload.telefono
  end

  test "formulario de nueva dirección" do
    get new_direccion_path
    assert_response :success
  end

  test "editar una dirección con comuna inválida re-renderiza el formulario" do
    direccion = @cliente.direcciones.first
    patch direccion_path(direccion), params: { direccion: { etiqueta: direccion.etiqueta, comuna: "Ñuñoa", calle: direccion.calle } }
    assert_response :unprocessable_entity
  end

  test "agregar una nueva dirección" do
    assert_difference "@cliente.direcciones.count", 1 do
      post direcciones_path, params: { direccion: { etiqueta: "Oficina", comuna: "Las Condes", calle: "Apoquindo 4500", numero_depto: "Depto 12" } }
    end
    assert_redirected_to perfil_path
  end

  test "no se puede agregar una dirección con comuna fuera de la lista" do
    assert_no_difference "@cliente.direcciones.count" do
      post direcciones_path, params: { direccion: { etiqueta: "Otra", comuna: "Ñuñoa", calle: "Calle 1" } }
    end
    assert_response :unprocessable_entity
  end

  test "editar una dirección propia" do
    direccion = @cliente.direcciones.first
    patch direccion_path(direccion), params: { direccion: { etiqueta: "Casa nueva", comuna: direccion.comuna, calle: direccion.calle } }
    assert_redirected_to perfil_path
    assert_equal "Casa nueva", direccion.reload.etiqueta
  end

  test "no se puede editar la dirección de otro cliente" do
    otro = crear_cliente
    otra_direccion = crear_direccion(otro)

    patch direccion_path(otra_direccion), params: { direccion: { etiqueta: "Hackeada" } }
    assert_response :not_found
    assert_not_equal "Hackeada", otra_direccion.reload.etiqueta
  end

  test "eliminar una dirección cuando hay más de una" do
    crear_direccion(@cliente, etiqueta: "Oficina")
    direccion = @cliente.direcciones.find_by(etiqueta: "Oficina")

    assert_difference "@cliente.direcciones.count", -1 do
      delete direccion_path(direccion)
    end
    assert_redirected_to perfil_path
  end

  test "no se puede eliminar la última dirección" do
    direccion = @cliente.direcciones.sole

    assert_no_difference "@cliente.direcciones.count" do
      delete direccion_path(direccion)
    end
    assert_redirected_to perfil_path
  end
end
