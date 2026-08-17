require "test_helper"

class WhatsappOrderMessageServiceTest < ActiveSupport::TestCase
  test "el mensaje incluye productos, subtotal, envío cobrado, total, fecha y dirección" do
    producto = crear_producto(nombre: "Salmón chico", precio: 4500)
    pedido = crear_pedido(productos: producto)
    pedido.calcular_total

    texto = WhatsappOrderMessageService.new(pedido).texto

    assert_match pedido.codigo_pedido, texto
    assert_match "Salmón chico x1", texto
    assert_match "Envío: 2.000 $", texto
    assert_match "Total: 6.500 $", texto
    assert_match pedido.direccion_calle, texto
  end

  test "el mensaje muestra Gratis cuando el envío es gratis" do
    producto = crear_producto(precio: CostoEnvio::GRATIS_DESDE)
    pedido = crear_pedido(productos: producto)
    pedido.calcular_total

    texto = WhatsappOrderMessageService.new(pedido).texto
    assert_match "Envío: Gratis", texto
  end

  test "url arma un link wa.me con el texto codificado" do
    pedido = crear_pedido
    url = WhatsappOrderMessageService.new(pedido).url

    assert_match %r{\Ahttps://wa\.me/\d+\?text=}, url
  end
end
