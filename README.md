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
- Venta por pieza/porción (no por kilo completo): salmón ahumado en pieza pequeña o grande, salmón ahumado desmenuzado y paté de salmón ahumado. ~25 kg disponibles por semana en total.
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

- [ ] **Fotos y descripciones reales de producto/"Quiénes somos"** — hoy varias son placeholders (fotos genéricas reutilizadas entre secciones, texto de ejemplo). Joaquín las va a ir subiendo/escribiendo directamente.
  - **2026-09-10, primera tanda de fotos reales subida.** Joaquín subió 11 fotos nuevas a `public/docs/productos/` (varios ángulos por producto: `salmon-desmenuzado[.-1-3].jpeg`, `salmon-pieza-chica-[1-3].jpeg`, `salmon-pieza-grande[.-2-3].jpeg`) — **todavía sin asignar a ningún producto**, Joaquín va a elegir a mano cuál usar por producto y avisar el nombre exacto para escribirlo en "Archivo de foto" (`Product#foto_filename`, un solo archivo por producto, no hay galería — ver "Modelos principales"). No llegó ninguna foto nueva para "Paté de Salmón Ahumado".
  - **Renombre de las 2 fotos placeholder originales** (a pedido de Joaquín, mismo día): `salmon-pieza-pequena.jpg` → `salmones-recien-salidos-1.jpg`, `salmon-pieza-grande.jpg` → `salmones-recien-salidos-2.jpg` (con `git mv`, conservan historial). Se actualizó el `foto_filename` de los 4 productos de la base de **desarrollo** que apuntaban a los nombres viejos (ids 1 y 4 → `salmones-recien-salidos-1.jpg`; ids 2 y 3 → `salmones-recien-salidos-2.jpg`). **Falta hacer lo mismo en producción** desde `/admin/productos` (editar "Archivo de foto" de cada producto) — la base de producción es independiente y nadie la tocó.
  - **Banners** (`public/docs/banners/`): las 4 fotos de esa carpeta eran copias idénticas del mismo placeholder genérico (mismo tamaño de archivo en las 4). `catalogo-hero.jpg` estaba huérfano — la clase `.catalogo-hero` que lo usaba (banner del catálogo, agregado 2026-08-05) ya no existía en el CSS ni en ninguna vista, se ve que se sacó en algún rediseño posterior sin borrar el archivo — **se eliminó** (2026-09-10, a pedido de Joaquín). Los 3 banners que sí se usan se renombraron con el mismo patrón `salmon-recien-salido-<dónde se usa>.jpg` (2026-09-10, a pedido de Joaquín): `home-hero.jpg` → `salmon-recien-salido-home.jpg` (`.hero` en `application.css`), `nuestro-proceso.jpg` → `salmon-recien-salido-nuestro-proceso.jpg` (sección "Nuestro proceso" en `nosotros.html.erb`), `quienes-somos.jpg` → `salmon-recien-salido-quienes-somos.jpg` (usado tanto en `nosotros.html.erb` como en la sección "Quiénes somos" de `inicio.html.erb`). Las 3 siguen siendo el mismo placeholder genérico — falta reemplazarlas por fotos reales, igual que las de producto.
- [ ] **Responsive / versión mobile** — el sitio está pensado y probado sobre todo en pantalla de PC; falta una pasada página por página en el teléfono para confirmar que los breakpoints (`@media (max-width: 768px)` en `application.css`) se ven bien. **En progreso, sin commitear todavía**: el nav ya tiene un menú hamburguesa nuevo para mobile (`app/javascript/controllers/nav_menu_controller.js`) — falta que Joaquín lo confirme visualmente en su teléfono antes de commitear, y seguir con el resto de páginas (hero, collage de productos, catálogo con filtros, checkout, etc.).
- [ ] Contenido de texto por revisar en páginas que puedan tener todavía algo de relleno (ej. alguna bajada en "Nuestros productos") — falta que Joaquín confirme si queda algo por reemplazar antes de la publicación SEO.

### Pendiente: otros

- [ ] **Redimensionar fotos de producto.** Hoy el catálogo y la ficha de producto muestran el mismo archivo tal cual se subió (las fotos nuevas pesan ~1-1.5 MB cada una) — no hay una versión chica para la tarjeta del catálogo y otra grande para la ficha, así que en el catálogo el navegador descarga la foto de tamaño completo solo para achicarla visualmente en una tarjeta pequeña. No rompe nada, pero hace más lenta la carga (sobre todo en el celular, con datos móviles). Se arregla generando 1-2 tamaños por foto al subirla (miniatura para el catálogo + una versión más liviana para la ficha).
- [ ] **Mejorar el PDF del comprobante de pedido y el Excel de despacho del admin** — a pedido de Joaquín, sin especificar todavía en qué sentido (diseño, contenido, o ambos); falta que aclare qué le gustaría cambiar de cada uno.
- [ ] **Idea: paso de confirmación cuando la dirección no se verifica del todo** (propuesta por Joaquín, 2026-09-10). Hoy `GeocodificadorService` corre en silencio durante el checkout y el cliente nunca se entera del resultado: si Nominatim no encuentra la dirección, o si solo la encuentra reintentando sin el número de la casa (calle real pero número no cargado en OpenStreetMap), el pedido se guarda igual, sin avisar nada. La idea es agregar un paso intermedio que le muestre algo al cliente **solo en esos dos casos dudosos** (dirección no encontrada, o encontrada en una ubicación distinta a la que escribió) — algo como "no pudimos confirmar esta dirección con exactitud, revísala antes de continuar" — para que la corrija ahí mismo si se equivocó, en vez de que el negocio recién lo note el día del despacho. Cuando la dirección se encuentra tal cual (con número), el flujo sigue exactamente igual que hoy, sin ningún paso extra. Falta definir el diseño de esa pantalla/paso.

