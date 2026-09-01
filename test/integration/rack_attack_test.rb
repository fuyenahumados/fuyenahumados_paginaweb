require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    @original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rack::Attack.cache.store = @original_store
  end

  test "bloquea después de 5 intentos de login por minuto contra el mismo email" do
    cliente = crear_cliente(password: "password123")

    5.times do
      post user_session_path, params: { user: { email: cliente.email, password: "clave-incorrecta" } }
      assert_response :unprocessable_entity
    end

    post user_session_path, params: { user: { email: cliente.email, password: "clave-incorrecta" } }
    assert_response :too_many_requests
  end

  test "bloquea después de 10 intentos de login por IP en 20 segundos, aunque cambie el email" do
    10.times do |i|
      post user_session_path, params: { user: { email: "no-existe-#{i}@test.cl", password: "x" } }
      assert_response :unprocessable_entity
    end

    post user_session_path, params: { user: { email: "no-existe-11@test.cl", password: "x" } }
    assert_response :too_many_requests
  end
end
