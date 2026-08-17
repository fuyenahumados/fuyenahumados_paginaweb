require "test_helper"

class OrderItemTest < ActiveSupport::TestCase
  test "requiere cantidad y precio_unitario mayores a cero" do
    pedido = crear_pedido
    producto = crear_producto

    item = pedido.order_items.new(product: producto, cantidad: 0, precio_unitario: 1000)
    assert_not item.valid?

    item.cantidad = 1
    item.precio_unitario = 0
    assert_not item.valid?
  end

  test "subtotal multiplica cantidad por precio_unitario" do
    pedido = crear_pedido
    item = pedido.order_items.create!(product: crear_producto, cantidad: 3, precio_unitario: 1500)

    assert_equal 4500, item.subtotal
  end
end
