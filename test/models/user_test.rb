require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "requiere nombre, apellido y teléfono" do
    usuario = User.new(email: "a@test.cl", password: "password123", nombre: nil, apellido: nil, telefono: nil)
    assert_not usuario.valid?
    assert_includes usuario.errors[:nombre], "no puede estar en blanco"
    assert_includes usuario.errors[:apellido], "no puede estar en blanco"
    assert_includes usuario.errors[:telefono], "no puede estar en blanco"
  end

  test "el teléfono debe cumplir el formato esperado" do
    usuario = crear_cliente
    usuario.telefono = "no es un telefono"
    assert_not usuario.valid?

    usuario.telefono = "+56 9 1234 5678"
    assert usuario.valid?
  end

  test "el teléfono no es obligatorio para una cuenta creada vía Google" do
    usuario = User.new(email: "google@test.cl", password: "password123", nombre: "Ana", apellido: "Pérez", provider: "google_oauth2", uid: "1")
    assert usuario.valid?
  end

  test "role por defecto es cliente y admite admin" do
    cliente = crear_cliente
    admin = crear_admin

    assert cliente.cliente?
    assert admin.admin?
  end

  test "nombre_completo concatena nombre y apellido" do
    usuario = crear_cliente(nombre: "Ana", apellido: "Pérez")
    assert_equal "Ana Pérez", usuario.nombre_completo
  end

  test "direccion_principal devuelve la marcada como principal" do
    usuario = crear_cliente
    crear_direccion(usuario, etiqueta: "Casa")
    oficina = crear_direccion(usuario, etiqueta: "Oficina")
    oficina.update!(principal: true)

    assert_equal oficina, usuario.reload.direccion_principal
  end

  test "direccion_principal cae a la primera si ninguna está marcada" do
    usuario = crear_cliente
    assert_nil usuario.direccion_principal

    primera = crear_direccion(usuario)
    assert_equal primera, usuario.reload.direccion_principal
  end

  test "crear_o_promover_admin! crea un admin nuevo con la contraseña dada" do
    usuario = User.crear_o_promover_admin!(email: "nuevo-admin@test.cl", password: "password123")

    assert usuario.persisted?
    assert usuario.admin?
    assert usuario.valid_password?("password123")
  end

  test "crear_o_promover_admin! promueve una cuenta existente sin pisar su contraseña" do
    cliente = crear_cliente(email: "promovido@test.cl", password: "clave-original")

    usuario = User.crear_o_promover_admin!(email: "promovido@test.cl", password: "otra-clave-cualquiera")

    assert_equal cliente.id, usuario.id
    assert usuario.admin?
    assert usuario.valid_password?("clave-original")
    assert_not usuario.valid_password?("otra-clave-cualquiera")
  end

  test "borrar el usuario borra sus pedidos y direcciones" do
    usuario = crear_cliente
    crear_direccion(usuario)
    pedido = crear_pedido(usuario: usuario)

    assert_difference [ "Order.count", "Direccion.count" ], -1 do
      usuario.destroy
    end
    assert_not Order.exists?(pedido.id)
  end
end
