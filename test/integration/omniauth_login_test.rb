require "test_helper"

class OmniauthLoginTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.mock_auth[:facebook] = nil
  end

  def mock_auth(provider, email:, uid: "1234567890", first_name: "Nueva", last_name: "Clienta")
    OmniAuth::AuthHash.new(
      provider: provider,
      uid: uid,
      info: OmniAuth::AuthHash::InfoHash.new(email: email, first_name: first_name, last_name: last_name)
    )
  end

  callback_path_por_proveedor = {
    "google_oauth2" => :user_google_oauth2_omniauth_callback_path,
    "facebook" => :user_facebook_omniauth_callback_path
  }

  callback_path_por_proveedor.each do |provider, callback_path_helper|
    test "un visitante nuevo se registra con #{provider} sin necesidad de teléfono" do
      entrar_con_token!

      assert_difference "User.count", 1 do
        get send(callback_path_helper), env: { "omniauth.auth" => mock_auth(provider, email: "nueva.#{provider}@test.cl") }
      end

      assert_redirected_to root_path
      usuario = User.find_by(email: "nueva.#{provider}@test.cl")
      assert usuario.present?
      assert usuario.cliente?
      assert_equal provider, usuario.provider
      assert_nil usuario.telefono
    end

    test "un mismo usuario de #{provider} que vuelve a entrar no crea una cuenta duplicada" do
      entrar_con_token!
      auth = mock_auth(provider, email: "repite.#{provider}@test.cl", uid: "999")

      assert_difference "User.count", 1 do
        get send(callback_path_helper), env: { "omniauth.auth" => auth }
      end
      delete destroy_user_session_path

      assert_no_difference "User.count" do
        get send(callback_path_helper), env: { "omniauth.auth" => auth }
      end
      assert_redirected_to root_path
    end

    test "un cliente que ya tenía cuenta por email/password se vincula a #{provider} en vez de duplicarse" do
      entrar_con_token!
      cliente = crear_cliente(email: "vinculo.#{provider}@test.cl")

      assert_no_difference "User.count" do
        get send(callback_path_helper), env: { "omniauth.auth" => mock_auth(provider, email: "vinculo.#{provider}@test.cl", uid: "555") }
      end

      assert_redirected_to root_path
      assert_equal provider, cliente.reload.provider
    end
  end
end
