require "simplecov"
SimpleCov.start "rails" do
  skip "/test/"
  minimum_coverage 90
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Métodos de fábrica para armar objetos válidos en los tests. No se usan fixtures
# porque Order/Direccion tienen callbacks (before_validation/before_save) y
# validaciones cruzadas que las fixtures se saltan — es más simple y confiable
# crear los objetos pasando siempre por las validaciones reales.
module TestFactories
  def crear_token_acceso(token: "token-test-#{SecureRandom.hex(4)}", activo: true)
    AccessToken.create!(token: token, activo: activo)
  end

  # Solo para integration tests: simula entrar por el link con token secreto,
  # que es lo primero que exige ApplicationController#verificar_acceso.
  def entrar_con_token!(token: nil)
    token ||= crear_token_acceso.token
    get "/acceso/#{token}"
  end

  # Solo para integration tests: login real vía POST (la protección CSRF está
  # desactivada en el entorno de test, así que no hace falta el token).
  def iniciar_sesion!(usuario, password: "password123")
    post user_session_path, params: { user: { email: usuario.email, password: password } }
  end

  def crear_cliente(email: "cliente#{SecureRandom.hex(4)}@test.cl", password: "password123", **attrs)
    User.create!(
      email: email, password: password, role: :cliente,
      nombre: "Test", apellido: "Cliente", telefono: "+56911111111",
      **attrs
    )
  end

  def crear_admin(email: "admin#{SecureRandom.hex(4)}@test.cl", password: "password123", **attrs)
    User.create!(
      email: email, password: password, role: :admin,
      nombre: "Test", apellido: "Admin", telefono: "+56922222222",
      **attrs
    )
  end

  def crear_direccion(usuario, etiqueta: "Casa", comuna: "Providencia", calle: "Calle 123", **attrs)
    usuario.direcciones.create!(etiqueta: etiqueta, comuna: comuna, calle: calle, **attrs)
  end

  def crear_producto(nombre: "Producto Test #{SecureRandom.hex(4)}", precio: 5000, stock: 10, activo: true, **attrs)
    Product.create!(nombre: nombre, precio: precio, stock: stock, activo: activo, **attrs)
  end

  # Crea un pedido válido y sus order_items. `productos` puede ser un producto
  # solo o una lista; por defecto crea uno nuevo con stock suficiente.
  def crear_pedido(usuario: nil, productos: nil, estado: :pendiente_pago, fecha_entrega: Order.proximo_viernes_habil, **attrs)
    productos = Array(productos.presence || crear_producto)

    pedido = Order.new(
      user:              usuario,
      nombre_contacto:   usuario&.nombre || "Invitado",
      apellido_contacto: usuario&.apellido || "Test",
      telefono_contacto: usuario&.telefono || "+56911111111",
      email_contacto:    usuario&.email || "invitado#{SecureRandom.hex(4)}@test.cl",
      direccion_calle:   "Calle 123",
      direccion_comuna:  "Providencia",
      fecha_entrega:     fecha_entrega,
      total:             0,
      **attrs
    )
    pedido.save!

    productos.each do |producto|
      pedido.order_items.create!(product: producto, cantidad: 1, precio_unitario: producto.precio)
    end
    pedido.calcular_total
    pedido.update!(estado: estado) unless estado.to_s == "pendiente_pago"

    pedido
  end
end

module ActiveSupport
  class TestCase
    include TestFactories

    # Coverage con SimpleCov es más confiable en un solo proceso.
    parallelize(workers: 1)
  end
end
