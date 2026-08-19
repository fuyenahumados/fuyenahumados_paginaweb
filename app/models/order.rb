class Order < ApplicationRecord
  belongs_to :user, optional: true
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items
  has_many :order_status_changes, -> { order(created_at: :asc) }, dependent: :destroy

  enum :estado, {
    pendiente_pago: 0,
    pagado:         1,
    en_preparacion: 2,
    despachado:     3,
    entregado:      4,
    cancelado:      5
  }

  before_validation :generar_codigo_pedido, on: :create

  after_create :registrar_historial_estado
  after_update :registrar_historial_estado, if: :saved_change_to_estado?

  validates :codigo_pedido, presence: true, uniqueness: true
  validates :total, numericality: { greater_than_or_equal_to: 0 }
  validates :envio, numericality: { greater_than_or_equal_to: 0 }
  validates :nombre_contacto, :apellido_contacto, :direccion_calle, presence: true
  validates :direccion_comuna, presence: true, inclusion: { in: Direccion::COMUNAS }
  validates :telefono_contacto, presence: true, format: { with: User::TELEFONO_FORMATO, message: "no es un número de teléfono válido" }
  validates :email_contacto, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "no es un email válido" }
  validates :fecha_entrega, presence: true
  validate :fecha_entrega_debe_ser_viernes
  validate :fecha_entrega_no_puede_ser_antes_del_proximo_viernes_habil, on: :create

  # Los despachos son solo los viernes, y no se puede pedir para el mismo día:
  # si hoy es viernes, la próxima fecha disponible es el viernes siguiente (7 días después),
  # no hoy. `next_occurring` de ActiveSupport ya tiene ese comportamiento.
  def self.proximo_viernes_habil(desde: Date.current)
    desde.next_occurring(:friday)
  end

  def nombre_completo_contacto
    "#{nombre_contacto} #{apellido_contacto}"
  end

  def direccion_completa
    [ direccion_calle, direccion_numero_depto, direccion_comuna ].reject(&:blank?).join(", ")
  end

  def invitado?
    user.nil?
  end

  def subtotal_productos
    order_items.sum { |i| i.cantidad * i.precio_unitario }
  end

  def calcular_total
    subtotal = subtotal_productos
    envio_calculado = CostoEnvio.calcular(subtotal)
    update!(envio: envio_calculado, total: subtotal + envio_calculado)
  end

  private

  def registrar_historial_estado
    order_status_changes.create!(estado: estado)
  end

  def generar_codigo_pedido
    loop do
      self.codigo_pedido = "FUY-#{SecureRandom.hex(3).upcase}"
      break unless Order.exists?(codigo_pedido: codigo_pedido)
    end
  end

  def fecha_entrega_debe_ser_viernes
    return if fecha_entrega.blank?
    errors.add(:fecha_entrega, "debe ser un día viernes (los despachos son solo los viernes)") unless fecha_entrega.friday?
  end

  def fecha_entrega_no_puede_ser_antes_del_proximo_viernes_habil
    return if fecha_entrega.blank?
    minimo = self.class.proximo_viernes_habil
    if fecha_entrega < minimo
      errors.add(:fecha_entrega, "debe ser el #{minimo.strftime('%d/%m/%Y')} o una fecha posterior")
    end
  end
end
