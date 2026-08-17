require "test_helper"

class OrderStatusChangeTest < ActiveSupport::TestCase
  test "requiere estado" do
    pedido = crear_pedido
    cambio = pedido.order_status_changes.new(estado: nil)
    assert_not cambio.valid?
  end

  test "pertenece a un pedido" do
    pedido = crear_pedido
    cambio = pedido.order_status_changes.last
    assert_equal pedido, cambio.order
  end
end
