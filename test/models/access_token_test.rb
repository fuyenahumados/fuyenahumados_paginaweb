require "test_helper"

class AccessTokenTest < ActiveSupport::TestCase
  test "requiere token" do
    token = AccessToken.new(token: nil)
    assert_not token.valid?
    assert_includes token.errors[:token], "no puede estar en blanco"
  end

  test "el token debe ser único" do
    crear_token_acceso(token: "repetido")
    duplicado = AccessToken.new(token: "repetido", activo: true)
    assert_not duplicado.valid?
  end

  test "valido? es true solo para un token activo existente" do
    crear_token_acceso(token: "bueno", activo: true)
    crear_token_acceso(token: "inactivo", activo: false)

    assert AccessToken.valido?("bueno")
    assert_not AccessToken.valido?("inactivo")
    assert_not AccessToken.valido?("no-existe")
    assert_not AccessToken.valido?(nil)
  end
end
