require "test_helper"

class PagesTest < ActionDispatch::IntegrationTest
  setup { entrar_con_token! }

  test "la home carga" do
    get root_path
    assert_response :success
  end

  test "la página nosotros carga" do
    get nosotros_path
    assert_response :success
  end
end
