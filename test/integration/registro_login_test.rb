require "test_helper"

class RegistroLoginTest < ActionDispatch::IntegrationTest
  test "un visitante puede registrarse con dirección incluida y queda logueado" do
    entrar_con_token!

    assert_difference [ "User.count", "Direccion.count" ], 1 do
      post user_registration_path, params: {
        user: {
          nombre: "Nueva", apellido: "Clienta", email: "nueva@test.cl",
          telefono: "+56911112222", password: "password123", password_confirmation: "password123",
          direcciones_attributes: {
            "0" => { etiqueta: "Casa", comuna: "Providencia", calle: "Los Leones 100" }
          }
        }
      }
    end

    assert_redirected_to root_path
    usuario = User.find_by(email: "nueva@test.cl")
    assert usuario.present?
    assert usuario.cliente?
    assert_equal "Casa", usuario.direccion_principal.etiqueta
  end

  test "no se puede registrar con datos inválidos" do
    entrar_con_token!

    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: { nombre: "", apellido: "", email: "no-es-email", telefono: "123", password: "abc", password_confirmation: "xyz" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "login con credenciales correctas deja entrar, incorrectas no" do
    entrar_con_token!
    cliente = crear_cliente(password: "password123")

    iniciar_sesion!(cliente, password: "clave-incorrecta")
    assert_response :unprocessable_entity

    iniciar_sesion!(cliente)
    assert_redirected_to root_path
    follow_redirect!
    assert_match cliente.nombre, response.body
  end

  test "logout cierra la sesión" do
    entrar_con_token!
    cliente = crear_cliente(password: "password123")
    iniciar_sesion!(cliente)

    delete destroy_user_session_path
    assert_redirected_to root_path

    get perfil_path
    assert_redirected_to new_user_session_path
  end

  test "un admin logueado no puede entrar a rutas solo-clientes como el perfil" do
    entrar_con_token!
    admin = crear_admin(password: "password123")
    iniciar_sesion!(admin)

    get perfil_path
    assert_redirected_to admin_root_path
  end
end
