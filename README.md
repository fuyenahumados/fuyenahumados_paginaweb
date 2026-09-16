# Salmón Ahumado Fuyén — Página Web

Notas de proyecto (para Joaquín y para Claude). Este archivo se mantiene actualizado
a medida que avanza el desarrollo — no es documentación estática.

## Reglas de trabajo con Claude

- **Nunca hacer `git commit` ni `git push` sin preguntar primero**, aunque el pedido
  del cambio haya sido explícito y claro. Mostrar los cambios hechos y esperar
  confirmación antes de comitear.

## Qué es esto

Tienda online para vender salmón ahumado artesanal, mientras la formalización
legal del negocio está pendiente.

- **Sitio público** (cualquiera con el link puede entrar) pero con `X-Robots-Tag: noindex`
  para no aparecer en buscadores mientras Joaquín solo comparte el link a mano (fase
  de pruebas antes de la publicación SEO formal, ver `## Pendiente`).
- Pago por transferencia bancaria (sin pasarela de pago).
- Venta por pieza/porción (no por kilo completo): salmón ahumado en pieza pequeña o grande, y salmón ahumado desmenuzado. ~25 kg disponibles por semana en total.
- Ciclo de producción semanal, entregas los viernes.

## Descripción y funciones principales

Sitio a medida para que Joaquín venda salmón ahumado artesanal por internet sin
depender de un marketplace. No hay pasarela de pago: el flujo completo está pensado
para transferencia bancaria coordinada por WhatsApp, con el negocio confirmando el
pago a mano.

**Para el cliente:**
- Catálogo con búsqueda por texto, filtro de precio (rangos predefinidos) y orden (precio/nombre/más nuevos), tarjetas con foto y stepper de cantidad que agrega al carrito sin recargar la página.
- Ficha de producto individual con foto grande, descripción, reseñas de otros clientes (estrellas 1-5 + comentario opcional) y formulario para dejar la propia — solo si el cliente compró ese producto antes.
- Registro/login por email o con Google (Devise + OmniAuth), o como invitado sin cuenta. Perfil con datos propios, historial de pedidos, reseñas dejadas, y una o varias direcciones de entrega (etiqueta libre, comuna restringida a las 5 que cubre el reparto, número de depto/casa opcional).
- Carrito en 2 columnas (productos editables + resumen) → checkout en 2 pasos: datos de envío (prellenados desde el perfil si hay sesión, con selector de direcciones guardadas) con resumen en vivo, y fecha de entrega elegida en un calendario que solo habilita viernes futuros (no se puede pedir para "hoy mismo" si hoy es viernes).
- Costo de envío fijo ($2.000, gratis desde $40.000 en productos) visible en carrito, checkout, WhatsApp, PDF y Excel — política centralizada en `CostoEnvio`.
- Al confirmar, el pedido queda "pendiente de pago" y la pantalla principal es un botón que abre WhatsApp con el mensaje del pedido ya escrito (productos, total, envío, fecha y dirección) para coordinar el pago — el negocio confirma a mano tras revisar la transferencia. También se puede descargar el pedido como PDF.
- Consulta de cualquier pedido por código sin necesidad de cuenta (`/mi-pedido`).
- Recuperación de acceso también por WhatsApp (no hay email/SMTP configurado): el cliente escribe, el admin le resetea la contraseña desde el panel y se la pasa por el chat.

**Para el negocio (panel admin):**
- Pedidos: ver, buscar (por código/nombre/email), filtrar por fecha de entrega, avanzar el estado (pendiente de pago → pagado → en preparación → despachado → entregado) o cancelar — siempre confirmando el pago a mano tras revisar WhatsApp. También se pueden cargar pedidos manuales (ventas por fuera del sitio) directamente desde el panel.
- Descarga de un Excel filtrado por una fecha de despacho puntual (un viernes), con todo lo que hay que preparar esa semana y a quién.
- CRUD completo de productos (bloqueado el borrado si el producto ya tiene pedidos asociados, para no perder historial de ventas).
- Clientes: listado con búsqueda, detalle con su historial de pedidos, borrado (bloqueado igual si tiene pedidos) y reseteo de contraseña para pasarle por WhatsApp.

## Stack

- Ruby on Rails 8.1.3 + PostgreSQL, Hotwire (Turbo + Stimulus) para las interacciones sin recargar página.
- Devise para autenticación (roles `:cliente`/`:admin`) + OmniAuth para login con Google.
- `rack-attack` para rate limiting en login/recuperar contraseña (el sitio es público, sin gate de acceso).
- `caxlsx` (Excel de despacho) y `prawn`/`prawn-table` (PDF del pedido) — ninguna depende de un binario externo, importante para Render.
- Desplegado en Render.com (**filesystem efímero** — por eso las fotos de producto son assets estáticos del repo, ver "Decisiones importantes").
- Tests: Minitest + SimpleCov (mínimo de cobertura configurado, falla el proceso si baja de 90%), Brakeman y Rubocop corriendo en CI (`.github/workflows/ci.yml`).

## Modelos principales

- `User` (Devise, role enum: cliente/admin; nombre/apellido separados; `provider`/`uid` para login con Google; teléfono obligatorio solo si no viene de un proveedor social).
- `Direccion` (pertenece a `User` — varias por cliente, con etiqueta libre, comuna restringida a las 5 que cubre el reparto — Lo Barnechea, Las Condes, Vitacura, Providencia, La Reina —, calle y número de depto/casa opcional; siempre hay una marcada `principal`, se reasigna sola si se borra la que estaba marcada).
- `Product` (nombre, descripción, precio, stock, `peso_descripcion`, `activo`, `foto_filename` — un solo archivo estático por producto en `public/docs/productos/`, sin galería —, `categoria` enum, hoy solo `ahumado`).
- `Order` (código autogenerado `FUY-XXXXXX`, `estado` enum con historial — ver `OrderStatusChange` —, `envio`/`total` calculados vía `CostoEnvio`, `fecha_entrega` — siempre viernes, validada según si el pedido es del sitio o cargado a mano por el admin —, copia propia de los datos de contacto/dirección al momento de la compra — para no perder esa información si el cliente edita su perfil después —, `lat`/`lng` opcionales verificados contra Nominatim, `source` `web`/`manual`).
- `OrderStatusChange` (pertenece a `Order` — una fila por cada cambio de estado, con su fecha; arma el historial que se ve en el detalle del pedido).
- `OrderItem` (cantidad, precio_unitario — fijado siempre desde el precio del producto al momento de la compra, nunca desde lo que mande el cliente).
- `Resena` (pertenece a `User` y `Product` — calificación 1-5, comentario opcional; un cliente reseña un producto una sola vez y solo si lo compró).
- `CostoEnvio` (no es un modelo de base de datos — objeto de política simple: `MONTO`/`GRATIS_DESDE`, usado por `Order`, el carrito, el checkout, el mensaje de WhatsApp y el Excel).

Nota de idioma: "direccion" y "categoria" están registrados como plurales irregulares en `config/initializers/inflections.rb` porque el inflector de Rails no adivina bien el español.

## Controladores principales

- `PagesController` (`inicio`, `nosotros`, `preguntas_frecuentes`, `privacidad`) — páginas estáticas de contenido.
- `ProductosController` (`index`, `show`) — catálogo con búsqueda/filtro/orden y ficha de producto.
- `CarritoController` (`show`, `agregar`, `actualizar`, `quitar`) — carrito en sesión, no se persiste en base hasta el checkout; responde con Turbo Stream para actualizar in-place.
- `CheckoutController` (`show`, `create`) — datos de envío, fecha de entrega, verificación best-effort de la dirección (`GeocodificadorService`) y creación del pedido.
- `PedidosPublicosController` (`nuevo`, `buscar`, `show`, `descargar`) — pantalla de "pedido recibido", consulta por código y descarga del PDF, todo sin necesidad de cuenta.
- `PerfilController` (`show`) — datos propios, direcciones, historial de pedidos y reseñas del cliente logueado (editar datos vive en Devise, ver abajo).
- `DireccionesController` (`new`, `create`, `edit`, `update`, `destroy`) — CRUD de direcciones del cliente.
- `ResenasController` (`create`) — anidado bajo productos, solo clientes que compraron el producto pueden reseñarlo.
- `Users::RegistrationsController` (Devise) — sobreescribe el registro estándar para redirigir a `/perfil` tras editar datos, en vez de a la home.
- `Users::OmniauthCallbacksController` — callback de login con Google.
- `Admin::PedidosController` (`index` con búsqueda/filtro por fecha, `show`, `new`/`create` para cargar pedidos manuales, `avanzar_estado`, `cancelar`, `exportar` a Excel).
- `Admin::ProductsController` (`index`, `new`, `create`, `edit`, `update`, `destroy`) — CRUD de productos.
- `Admin::UsersController` (`index` con búsqueda, `show`, `destroy`, `resetear_password` — genera una contraseña nueva para pasarle al cliente por WhatsApp).
- `Admin::BaseController` — base del panel admin (exige sesión + rol admin).
- `ApplicationController` — base de todo el sitio (desactiva flashes automáticos de Devise, agrega `X-Robots-Tag: noindex`).

## Servicios principales

Lógica de negocio que no encaja como método de modelo ni de controller, cada uno en su propio archivo bajo `app/services/` (convención del proyecto: no comparten código entre sí aunque arman contenido parecido, cada uno con su propio formato):

- `WhatsappOrderMessageService` — arma el texto del mensaje de WhatsApp que confirma un pedido (productos, subtotal, envío, total, dirección, fecha de entrega).
- `PedidosExcelExportService` — genera el `.xlsx` de despacho filtrado por fecha de entrega, para que el admin lo descargue desde `/admin/pedidos`.
- `PedidoReciboService` — genera el PDF del comprobante de pedido que el cliente puede descargar desde `/mi-pedido`.
- `GeocodificadorService` — se sigue usando hoy, en silencio: `CheckoutController#ubicar_direccion` lo llama en cada pedido para consultar Nominatim/OpenStreetMap y guardar `lat`/`lng` de referencia si la dirección se encuentra. No tiene ninguna UI (no hay mapa, ver "Decisiones importantes") y es **best-effort**: si Nominatim no responde o no encuentra la dirección, el pedido igual se confirma sin coordenadas — nunca bloquea una venta real por una limitación de un servicio externo gratuito.

## Decisiones importantes

Decisiones de diseño no obvias — el motivo importa para no volver a proponer lo mismo más adelante sin saber por qué se descartó:

- **Sin Active Storage/Cloudinary para fotos de producto.** Se probó y se descartó: no convencía depender de un servicio externo de storage. Las fotos son archivos estáticos versionados en el repo (`public/docs/productos/`, `Product#foto_filename` solo guarda el nombre) — el trade-off aceptado es que actualizar una foto requiere copiar el archivo, commitear y deployar (no se puede subir desde el admin), pero elimina cualquier dependencia externa y el problema del filesystem efímero de Render.
- **Sin mapa interactivo para direcciones.** Se probó con Leaflet + Nominatim (pin arrastrable en registro/perfil/checkout) y se sacó por completo — era solo ayuda visual, nunca la fuente de verdad de las coordenadas, y era la pieza más frágil del formulario. La verificación de dirección real sigue existiendo pero corre en el servidor (`GeocodificadorService`), sin UI de mapa.
- **Sin pasarela de pago.** El negocio funciona con transferencia bancaria coordinada por WhatsApp a propósito — no hay ningún flujo de pago automático ni se planea agregar uno mientras la formalización legal del negocio siga pendiente.
- **Sin SMTP/emails transaccionales.** "Recuperar contraseña" no usa email — el cliente escribe por WhatsApp y el admin resetea la contraseña a mano desde `/admin/users` (`resetear_password`). Decisión explícita: el negocio ya resuelve todo por WhatsApp, no tenía sentido sumar un proveedor de email solo para esto.
- **`db/seeds.rb` nunca crea productos ni usuarios admin, a propósito.** Solo crea un cliente de prueba y sus pedidos (si ya hay productos cargados). Productos y admins se gestionan desde el panel admin o `bin/rails admin:crear` — así correr `db:seed` en un ambiente nuevo nunca genera datos de negocio falsos que haya que borrar a mano.
- **Login con Facebook, eliminado del alcance (2026-09-10).** Se había implementado completo (botón, callback, credenciales) pero quedó trabado en la verificación de negocio que exige Meta; a pedido de Joaquín se sacó todo el código en vez de dejarlo pausado. Login con Apple también se descartó (costo del Apple Developer Program). Google es el único login social activo.
- **Base de datos en Render: todo comparte una sola base física.** El plan gratuito de Postgres de Render da una sola base (una connection string), no permite crear bases separadas para `cache`/`queue`/`cable` como espera Rails 8 por defecto. `config/database.yml` resuelve esto en `production` heredando el mismo `url: <%= ENV["DATABASE_URL"] %>` en las 4 conexiones (`primary`, `cache`, `queue`, `cable`) — en la práctica las 4 apuntan a la misma base física, pero no colisionan porque las tablas de Solid Cache/Queue/Cable tienen nombres únicos.
- **Cache en memoria en producción, no Solid Cache.** `solid_cache_entries` no se creaba bien en Render (`PG::UndefinedTable`) porque el plan gratuito no tiene Shell ni "one-off jobs" para correr `db:prepare` a mano sobre la base secundaria de cache. `config/environments/production.rb` usa `config.cache_store = :memory_store` en su lugar — no es durable entre reinicios del servidor, pero nada del sitio depende de que el cache sobreviva un restart. Si en algún momento se resuelve el problema de raíz, se puede volver a Solid Cache.
- **Paté de Salmón Ahumado, discontinuado (2026-09-10, a pedido de Joaquín).** No se produce más. El producto **no se borró de la base** — tiene 8 pedidos y 1 reseña asociados, y `Admin::ProductsController#destroy` bloquea a propósito el borrado de cualquier producto con pedidos ("para no perder historial de ventas"). Se desactivó (`activo: false`, ya no aparece en el catálogo ni su ficha) y se sacaron las menciones sueltas en el sitio (FAQ, este README). Mismo criterio aplica en producción: si tiene pedidos reales ahí, el admin tampoco va a poder borrarlo, solo desactivarlo desde `/admin/products`.

## Pendiente

### Pendiente: Publicación del sitio en internet

- [ ] **Sacar el header `X-Robots-Tag: noindex, nofollow`** (`app/controllers/application_controller.rb`,
      línea con `after_action`) — hoy queda a propósito, para no indexar el sitio mientras
      Joaquín solo comparte el link a mano. Sacarlo recién cuando el resto de este checklist
      (dominio, sitemap, robots.txt, títulos/meta description) esté listo — hacerlo antes
      solo deja que Google indexe una versión a medio terminar.
- [ ] Verificar que catálogo, checkout y home funcionen bien en producción (Render)
- [ ] Comprar dominio propio (ej. .cl en NIC Chile, o .com)
- [ ] Configurar Custom Domain en Render (Settings → Custom Domains) y apuntar
      los registros DNS (CNAME/A) según indique Render
- [ ] Crear cuenta en Google Search Console y verificar la propiedad del dominio
- [ ] Generar sitemap.xml (evaluar gema `sitemap_generator`) y subirlo a Search Console
- [ ] Agregar robots.txt en public/ permitiendo el rastreo (Allow: /)
- [ ] Revisar que cada página tenga <title> y meta description únicos para SEO
- [ ] Solicitar indexación manual de la home en Search Console para acelerar el
      proceso (puede tardar días a semanas de forma orgánica)

### Pendiente: contenido real y mobile

- [ ] **Fotos y descripciones reales de producto/"Quiénes somos"** — Joaquín las va subiendo/escribiendo directamente.
  - **2026-09-10, fotos reales de producto ya asignadas** (Joaquín las asignó él mismo desde `/admin/products`, verificado): Salmón Ahumado (200g-250g) → `salmon-pieza-chica-2.jpeg`, Salmón Ahumado (300g-350g) → `salmon-pieza-grande-3.jpeg`, Salmón Ahumado Desmenuzado → `salmon-desmenuzado-1.jpeg`.
  - **2026-09-15, home actualizada con contenido real (Joaquín, confirmado listo):** sección "Quiénes somos" de la home usa `quienes-somos-pablo-gellona.jpeg` (foto real del equipo, no placeholder). El collage de "Nuestros productos" de la home usa fotos reales de producto (`salmon-redimensionado-1.jpeg`, `salmon-redimensionado-2.jpeg`) más `salmon-recien-salido-home.jpg` (la misma foto del `.hero`, reutilizada a propósito).
  - **2026-09-16, replicado en producción (Joaquín, confirmado listo)** — las fotos/nombre/peso de producto ya quedaron iguales en dev y en producción.
  - **Pendiente todavía**: `/nosotros` ("Nuestro proceso") sigue mostrando el banner placeholder genérico (`salmon-recien-salido-nuestro-proceso.jpg`) — el texto de esa sección ya se actualizó con contenido real (2026-09-15), pero la foto todavía no. ("Sobre nosotros" ya tiene foto real, `quienes-somos-pablo-gellona.jpeg`.)
- [x] **Responsive / versión mobile** — el nav con menú hamburguesa (`app/javascript/controllers/nav_menu_controller.js`) ya está commiteado. Durante la sesión del 2026-09-15 se verificó con screenshots el collage de "Nuestros productos" y la grilla de catálogo en mobile (390px) — se ven bien. Sigue faltando una pasada de Joaquín en su teléfono real para el resto de páginas (checkout, carrito, perfil, etc.).

### Pendiente: otros

- [x] **Redimensionar fotos de producto/banners.** Las 6 fotos reales en uso (3 de producto + 3 de banners) pesaban 1-1.5 MB cada una a resolución original de cámara/celular (hasta 4054px de lado). Se redujeron a un máximo de 1600px de lado + recompresión JPEG (calidad 82, progressive), quedando entre 300-430 KB cada una (~3.5x más livianas) sin pérdida de calidad visible. Se sobreescribió el archivo tal cual (mismo nombre, no hay versión separada para catálogo vs ficha) — si en algún momento se quiere una miniatura aparte para el catálogo, es un paso más.
- [x] **Mejorar el PDF del comprobante de pedido y el Excel de despacho del admin** (2026-09-16).
  - PDF (`PedidoReciboService`): tabla de productos ahora incluye subtotal/envío/total adentro (antes quedaban como texto suelto afuera), agradecimiento arriba de todo, dirección/instrucciones y datos de contacto en dos columnas, texto justificado. Se probó agregar el logo y después se sacó, a pedido de Joaquín.
  - Excel (`PedidosExcelExportService`): encabezados en verde y negrita, una fila por producto (antes todo el detalle del pedido iba junto en una sola celda), fondo alternado gris claro/blanco por pedido (no por fila), dirección y comuna en columnas separadas, pedidos ordenados por comuna, columna A y las columnas separadoras con ancho fijo (no colapsadas), y dos tablas de resumen al lado de la principal: cantidad total por producto, y cuántos pedidos hay que despachar en cada comuna.

