require "test_helper"

class AccesoTest < ActionDispatch::IntegrationTest
  test "sin token en sesión, cualquier página redirige a acceso inválido" do
    get root_path
    assert_redirected_to acceso_invalido_path
  end

  test "un token válido abre la sesión y deja navegar el sitio" do
    token = crear_token_acceso.token
    get "/acceso/#{token}"
    assert_redirected_to root_path

    follow_redirect!
    assert_response :success
  end

  test "un token inactivo o inexistente muestra la página de inválido" do
    inactivo = crear_token_acceso(activo: false).token
    get "/acceso/#{inactivo}"
    assert_response :forbidden

    get "/acceso/no-existe"
    assert_response :forbidden
  end

  test "la página de acceso inválido es accesible sin sesión" do
    get acceso_invalido_path
    assert_response :success
  end

  test "toda respuesta manda X-Robots-Tag noindex" do
    entrar_con_token!
    get root_path
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
  end
end
