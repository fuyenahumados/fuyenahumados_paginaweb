require "test_helper"

class AdminProductsTest < ActionDispatch::IntegrationTest
  setup do
    entrar_con_token!
    @admin = crear_admin(password: "password123")
    iniciar_sesion!(@admin)
  end

  test "un cliente normal no puede entrar al panel admin" do
    cliente = crear_cliente(password: "password123")
    delete destroy_user_session_path
    iniciar_sesion!(cliente)

    get admin_products_path
    assert_redirected_to root_path
  end

  test "formulario de nuevo producto" do
    get new_admin_product_path
    assert_response :success
  end

  test "editar con datos inválidos re-renderiza el formulario" do
    producto = crear_producto
    patch admin_product_path(producto), params: { product: { nombre: producto.nombre, precio: -5, stock: producto.stock } }
    assert_response :unprocessable_entity
  end

  test "listar productos" do
    producto = crear_producto
    get admin_products_path
    assert_response :success
    assert_match producto.nombre, response.body
  end

  test "crear un producto" do
    assert_difference "Product.count", 1 do
      post admin_products_path, params: {
        product: { nombre: "Salmón nuevo", precio: 6000, stock: 5, activo: true, categoria: "ahumado" }
      }
    end
    assert_redirected_to admin_products_path
  end

  test "no se puede crear un producto con precio inválido" do
    assert_no_difference "Product.count" do
      post admin_products_path, params: { product: { nombre: "Malo", precio: 0, stock: 5 } }
    end
    assert_response :unprocessable_entity
  end

  test "editar un producto" do
    producto = crear_producto
    patch admin_product_path(producto), params: { product: { nombre: "Nombre editado", precio: producto.precio, stock: producto.stock } }
    assert_redirected_to admin_products_path
    assert_equal "Nombre editado", producto.reload.nombre
  end

  test "eliminar un producto sin pedidos asociados" do
    producto = crear_producto
    assert_difference "Product.count", -1 do
      delete admin_product_path(producto)
    end
    assert_redirected_to admin_products_path
  end

  test "no se puede eliminar un producto con pedidos asociados" do
    producto = crear_producto
    crear_pedido(productos: producto)

    assert_no_difference "Product.count" do
      delete admin_product_path(producto)
    end
    assert_redirected_to admin_products_path
  end
end
