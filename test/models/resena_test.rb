require "test_helper"

class ResenaTest < ActiveSupport::TestCase
  test "requiere calificacion entre 1 y 5" do
    cliente = crear_cliente
    producto = crear_producto
    crear_pedido(usuario: cliente, productos: producto)

    resena = Resena.new(user: cliente, product: producto, calificacion: 0)
    assert_not resena.valid?

    resena.calificacion = 6
    assert_not resena.valid?

    resena.calificacion = 5
    assert resena.valid?
  end

  test "un cliente no puede reseñar dos veces el mismo producto" do
    cliente = crear_cliente
    producto = crear_producto
    crear_pedido(usuario: cliente, productos: producto)

    Resena.create!(user: cliente, product: producto, calificacion: 4)
    duplicada = Resena.new(user: cliente, product: producto, calificacion: 5)

    assert_not duplicada.valid?
    assert_includes duplicada.errors[:user_id], "ya reseñó este producto"
  end

  test "no se puede reseñar un producto que el cliente nunca compró" do
    cliente = crear_cliente
    producto = crear_producto

    resena = Resena.new(user: cliente, product: producto, calificacion: 5)
    assert_not resena.valid?
    assert_includes resena.errors[:base], "Solo puedes reseñar productos que hayas comprado"
  end

  test "un pedido cancelado no cuenta como compra" do
    cliente = crear_cliente
    producto = crear_producto
    crear_pedido(usuario: cliente, productos: producto, estado: :cancelado)

    resena = Resena.new(user: cliente, product: producto, calificacion: 5)
    assert_not resena.valid?
  end

  test "esa regla de compra no se reaplica al editar una reseña existente" do
    cliente = crear_cliente
    producto = crear_producto
    pedido = crear_pedido(usuario: cliente, productos: producto)
    resena = Resena.create!(user: cliente, product: producto, calificacion: 3)

    pedido.destroy # el cliente "ya no compró" el producto

    resena.comentario = "Editando después"
    assert resena.valid?
  end
end
