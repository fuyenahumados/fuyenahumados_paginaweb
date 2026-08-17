# Esta seed SOLO crea datos de prueba para poder probar el flujo de compra
# en desarrollo: cliente de prueba + pedidos de prueba en distintos estados
# (catálogo → carrito → checkout → cambios de estado → export a Excel).
#
# A propósito NO crea: usuario admin, productos, descripciones ni imágenes.
# Eso es contenido real del negocio y se administra desde el panel admin
# (o, para el primer admin, con `bin/rails admin:crear EMAIL=... PASSWORD=...`
# — ver lib/tasks/admin.rake) — no queremos que contenido de negocio viva en
# código versionado que hay que editar y volver a correr.
#
# Los pedidos de prueba necesitan productos para poder crearse: si todavía no
# hay ningún producto cargado (primera vez que se corre la seed, antes de
# entrar al panel admin), esta seed crea el cliente y los tokens de acceso
# nomás, y avisa que faltan productos. Corre `bin/rails db:seed` de nuevo
# después de cargar productos desde el admin para que se generen los pedidos.

token_admin = "fuyen-admin-2024"
token_clientes = "fuyen-acceso-clientes"

AccessToken.find_or_create_by!(token: token_admin)
AccessToken.find_or_create_by!(token: token_clientes)

cliente = User.find_or_create_by!(email: "cliente@fuyen.cl") do |u|
  u.nombre    = "Cliente"
  u.apellido  = "de Prueba"
  u.telefono  = "+56911111111"
  u.password  = "12345678"
  u.role      = :cliente
end

cliente.direcciones.find_or_create_by!(etiqueta: "Casa") do |d|
  d.comuna = "Providencia"
  d.calle  = "Av. Providencia 1234, depto 56"
end

puts "Tokens de acceso:"
puts "  Admin:    /acceso/#{token_admin}"
puts "  Clientes: /acceso/#{token_clientes}"
puts "Cliente de prueba: cliente@fuyen.cl / 12345678"

if Product.none?
  puts "No hay productos cargados todavía — no se crearon pedidos de prueba."
  puts "Crea un admin con `bin/rails admin:crear EMAIL=... PASSWORD=...`, carga productos desde /admin/products y vuelve a correr `bin/rails db:seed`."
  return
end

if cliente.orders.any?
  puts "El cliente de prueba ya tiene pedidos — no se crean pedidos de prueba de nuevo."
  return
end

def crear_pedido_prueba(cliente, estado:, usuario: cliente, notas: nil)
  productos = Product.limit(2).to_a
  return if productos.empty?

  pedido = Order.create!(
    user:              usuario,
    nombre_contacto:   usuario&.nombre || "Invitado",
    apellido_contacto: usuario&.apellido || "de Prueba",
    telefono_contacto: usuario&.telefono || "+56922223333",
    email_contacto:    usuario&.email || "invitado@example.com",
    direccion_calle:   cliente.direccion_principal&.calle || "Calle de Prueba 123",
    direccion_comuna:  cliente.direccion_principal&.comuna || "Providencia",
    notas:             notas,
    total:             0,
    fecha_entrega:     Order.proximo_viernes_habil
  )

  productos.each do |producto|
    pedido.order_items.create!(product: producto, cantidad: 1, precio_unitario: producto.precio)
  end
  pedido.calcular_total
  pedido.update!(estado: estado) unless estado == :pendiente_pago

  pedido
end

crear_pedido_prueba(cliente, estado: :pendiente_pago)
crear_pedido_prueba(cliente, estado: :pagado)
crear_pedido_prueba(cliente, estado: :en_preparacion)
crear_pedido_prueba(cliente, estado: :despachado)
crear_pedido_prueba(cliente, estado: :entregado)
crear_pedido_prueba(cliente, estado: :pendiente_pago, usuario: nil, notas: "Dejar en conserjería (pedido de invitado)")

puts "Pedidos de prueba creados para cliente@fuyen.cl (uno por estado) + un pedido de invitado."
