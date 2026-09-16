class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  has_many :orders, dependent: :destroy
  has_many :direcciones, dependent: :destroy
  has_many :resenas, dependent: :destroy
  accepts_nested_attributes_for :direcciones

  enum :role, { cliente: 0, admin: 1 }

  TELEFONO_FORMATO = /\A\+?[\d\s]{8,15}\z/

  validates :nombre, presence: true
  validates :apellido, presence: true
  # El teléfono es obligatorio al registrarse por email/password, pero no para
  # una cuenta creada vía Google — se puede completar más adelante (perfil o
  # checkout) sin agregar fricción al login, a pedido de Joaquín.
  validates :telefono, presence: true, unless: -> { provider.present? }
  validates :telefono, format: { with: TELEFONO_FORMATO, message: "no es un número de teléfono válido" }, allow_blank: true
  # Solo puede haber un admin en todo el sistema, a pedido de Joaquín — nunca
  # se crea uno nuevo por accidente (ni por consola, ni por un futuro botón
  # en el panel). Para cambiarlo hay que primero bajar de rol al admin actual.
  validate :solo_un_admin_en_el_sistema, if: :admin?

  # Busca o crea el User correspondiente a un login con Google (auth es el
  # OmniAuth::AuthHash del proveedor). Si ya existe una cuenta con ese email
  # (creada por email/password, o por el otro proveedor), la vincula en vez de duplicarla.
  def self.from_omniauth(auth)
    return find_by(provider: auth.provider, uid: auth.uid) if exists?(provider: auth.provider, uid: auth.uid)

    usuario = find_by(email: auth.info.email)
    if usuario
      usuario.update!(provider: auth.provider, uid: auth.uid)
      return usuario
    end

    create!(
      provider: auth.provider,
      uid: auth.uid,
      email: auth.info.email,
      password: Devise.friendly_token[0, 20],
      nombre: auth.info.first_name.presence || auth.info.name,
      apellido: auth.info.last_name.presence || "",
      role: :cliente
    )
  end

  # Crea el único admin del sistema, o actualiza sus datos si ya existe (mismo
  # email) -- si ya hay un admin con OTRO email, `save!` falla con la
  # validación `solo_un_admin_en_el_sistema` (nunca se crea un segundo admin).
  # Usado por `bin/rails admin:crear` (lib/tasks/admin.rake) y por
  # config/initializers/admin_bootstrap.rb (creación automática en el boot del
  # server en producción, para plataformas sin Shell como el plan Free de Render).
  #
  # `forzar_password:` decide si se actualiza la contraseña cuando el admin ya
  # existía. `bin/rails admin:crear` la pasa en `true` -- si un humano lo corre
  # a mano pasando PASSWORD=algo, es porque quiere que quede esa. El bootstrap
  # automático de producción la deja en `false` a propósito: como corre en
  # cada boot del server con la misma variable de entorno, si la forzara
  # resetearía la contraseña cada vez que el server reinicia, aunque se haya
  # cambiado desde entonces por consola.
  def self.crear_o_promover_admin!(email:, password:, nombre: nil, apellido: nil, telefono: nil, forzar_password: false)
    usuario = find_or_initialize_by(email: email)
    usuario.password = password if usuario.new_record? || forzar_password
    usuario.nombre    = nombre    || usuario.nombre.presence    || "Admin"
    usuario.apellido  = apellido  || usuario.apellido.presence  || "Fuyén"
    usuario.telefono  = telefono  || usuario.telefono.presence  || "+56900000000"
    usuario.role      = :admin
    usuario.save!
    usuario
  end

  def nombre_completo
    "#{nombre} #{apellido}"
  end

  def direccion_principal
    direcciones.find_by(principal: true) || direcciones.first
  end

  def compro?(product)
    OrderItem.joins(:order)
             .where(product_id: product.id, orders: { user_id: id })
             .where.not(orders: { estado: :cancelado })
             .exists?
  end

  private

  def solo_un_admin_en_el_sistema
    return unless User.admin.where.not(id: id).exists?

    errors.add(:base, "Ya existe un admin en el sistema — solo puede haber uno.")
  end
end
