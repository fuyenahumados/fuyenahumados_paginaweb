require "test_helper"

class GoogleLoginTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  def mock_auth_google(email:, uid: "1234567890", first_name: "Nueva", last_name: "Clienta")
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: OmniAuth::AuthHash::InfoHash.new(email: email, first_name: first_name, last_name: last_name)
    )
  end

  test "un visitante nuevo se registra con Google sin necesidad de teléfono" do
    entrar_con_token!

    assert_difference "User.count", 1 do
      get user_google_oauth2_omniauth_callback_path, env: { "omniauth.auth" => mock_auth_google(email: "nueva.google@test.cl") }
    end

    assert_redirected_to root_path
    usuario = User.find_by(email: "nueva.google@test.cl")
    assert usuario.present?
    assert usuario.cliente?
    assert_equal "google_oauth2", usuario.provider
    assert_nil usuario.telefono
  end

  test "un mismo usuario de Google que vuelve a entrar no crea una cuenta duplicada" do
    entrar_con_token!
    auth = mock_auth_google(email: "repite.google@test.cl", uid: "999")

    assert_difference "User.count", 1 do
      get user_google_oauth2_omniauth_callback_path, env: { "omniauth.auth" => auth }
    end
    delete destroy_user_session_path

    assert_no_difference "User.count" do
      get user_google_oauth2_omniauth_callback_path, env: { "omniauth.auth" => auth }
    end
    assert_redirected_to root_path
  end

  test "un cliente que ya tenía cuenta por email/password se vincula a Google en vez de duplicarse" do
    entrar_con_token!
    cliente = crear_cliente(email: "vinculo@test.cl")

    assert_no_difference "User.count" do
      get user_google_oauth2_omniauth_callback_path, env: { "omniauth.auth" => mock_auth_google(email: "vinculo@test.cl", uid: "555") }
    end

    assert_redirected_to root_path
    assert_equal "google_oauth2", cliente.reload.provider
  end
end
