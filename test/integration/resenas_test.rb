require "test_helper"

class ResenasTest < ActionDispatch::IntegrationTest
  setup do
    @producto = crear_producto(nombre: "Salmón pieza chica")
  end

  test "un cliente que compró el producto puede dejar una reseña" do
    cliente = crear_cliente(password: "password123")
    crear_pedido(usuario: cliente, productos: @producto)
    iniciar_sesion!(cliente)

    get producto_path(@producto)
    assert_response :success
    assert_match "Publicar reseña", response.body

    assert_difference "Resena.count", 1 do
      post producto_resenas_path(@producto), params: { resena: { calificacion: 5, comentario: "Excelente" } }
    end
    assert_redirected_to producto_path(@producto)

    follow_redirect!
    assert_match "Excelente", response.body
    assert_no_match "Publicar reseña", response.body # ya reseñó, no se vuelve a mostrar el form
  end

  test "un cliente que no compró el producto no ve el formulario y no puede reseñar por request directo" do
    cliente = crear_cliente(password: "password123")
    iniciar_sesion!(cliente)

    get producto_path(@producto)
    assert_no_match "Publicar reseña", response.body

    assert_no_difference "Resena.count" do
      post producto_resenas_path(@producto), params: { resena: { calificacion: 5 } }
    end
    assert_redirected_to producto_path(@producto)
    follow_redirect!
    assert_match "Solo puedes reseñar productos que hayas comprado", response.body
  end

  test "un cliente no puede reseñar el mismo producto dos veces" do
    cliente = crear_cliente(password: "password123")
    crear_pedido(usuario: cliente, productos: @producto)
    iniciar_sesion!(cliente)

    post producto_resenas_path(@producto), params: { resena: { calificacion: 4 } }

    assert_no_difference "Resena.count" do
      post producto_resenas_path(@producto), params: { resena: { calificacion: 5 } }
    end
  end

  test "un invitado sin sesión no puede reseñar" do
    post producto_resenas_path(@producto), params: { resena: { calificacion: 5 } }
    assert_redirected_to new_user_session_path
  end

  test "la ficha de producto muestra el promedio y la lista de reseñas" do
    cliente = crear_cliente
    crear_pedido(usuario: cliente, productos: @producto)
    Resena.create!(user: cliente, product: @producto, calificacion: 4, comentario: "Muy bueno")

    get producto_path(@producto)
    assert_response :success
    assert_match "4.0", response.body
    assert_match "Muy bueno", response.body
    assert_match cliente.nombre, response.body
  end
end
