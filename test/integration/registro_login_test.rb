require "test_helper"

class RegistroLoginTest < ActionDispatch::IntegrationTest
  test "un visitante puede registrarse con dirección incluida y queda logueado" do
    assert_difference [ "User.count", "Direccion.count" ], 1 do
      post user_registration_path, params: {
        user: {
          nombre: "Nueva", apellido: "Clienta", email: "nueva@test.cl",
          telefono: "+56911112222", password: "password123", password_confirmation: "password123",
          direcciones_attributes: {
            "0" => { etiqueta: "Casa", comuna: "Providencia", calle: "Los Leones 100", numero_depto: "Depto 3" }
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
    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: { nombre: "", apellido: "", email: "no-es-email", telefono: "123", password: "abc", password_confirmation: "xyz" }
      }
    end
    assert_response :unprocessable_entity
    assert_no_match "Translation missing", response.body
    assert_match "Confirmación de contraseña", response.body
  end

  test "el login muestra un link para recuperar la contraseña" do
    get new_user_session_path
    assert_select "a[href=?]", new_user_password_path, text: "¿Olvidaste tu contraseña?"
  end

  test "pedir recuperar la contraseña envía un email y redirige al login" do
    cliente = crear_cliente(password: "password123")

    assert_emails 1 do
      post user_password_path, params: { user: { email: cliente.email } }
    end
    assert_redirected_to new_user_session_path
  end

  test "pedir recuperar la contraseña con un email que no existe muestra un error sin romper la página" do
    assert_no_emails do
      post user_password_path, params: { user: { email: "no-existe@test.cl" } }
    end
    assert_response :unprocessable_entity
    assert_no_match "Translation missing", response.body
  end

  test "login con credenciales correctas deja entrar, incorrectas no" do
    cliente = crear_cliente(password: "password123")

    iniciar_sesion!(cliente, password: "clave-incorrecta")
    assert_response :unprocessable_entity

    iniciar_sesion!(cliente)
    assert_redirected_to root_path
    follow_redirect!
    assert_match cliente.nombre, response.body
  end

  test "logout cierra la sesión" do
    cliente = crear_cliente(password: "password123")
    iniciar_sesion!(cliente)

    delete destroy_user_session_path
    assert_redirected_to root_path

    get perfil_path
    assert_redirected_to new_user_session_path
  end

  test "un admin logueado no puede entrar a rutas solo-clientes como el perfil" do
    admin = crear_admin(password: "password123")
    iniciar_sesion!(admin)

    get perfil_path
    assert_redirected_to admin_root_path
  end
end
