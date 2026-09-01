class Order < ApplicationRecord
  belongs_to :user, optional: true
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items
  has_many :order_status_changes, -> { order(created_at: :asc) }, dependent: :destroy
  accepts_nested_attributes_for :order_items, allow_destroy: true,
    reject_if: proc { |attrs| attrs["product_id"].blank? }

  SOURCES = %w[web manual].freeze

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
  validates :source, inclusion: { in: SOURCES }
  validate :fecha_entrega_debe_ser_viernes
  # Los pedidos manuales del admin sirven también para cargar ventas que ya
  # pasaron (alguien escribió por fuera antes de que existiera esta pantalla),
  # así que no tiene sentido exigirles la misma fecha mínima que al checkout.
  validate :fecha_entrega_no_puede_ser_antes_del_proximo_viernes_habil, on: :create, unless: :manual?
  validate :debe_tener_al_menos_un_producto, if: :manual?
  validate :stock_suficiente_por_item, if: :manual?

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

  def manual?
    source == "manual"
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

  def items_vigentes
    order_items.reject(&:marked_for_destruction?)
  end

  def debe_tener_al_menos_un_producto
    errors.add(:base, "Agrega al menos un producto.") if items_vigentes.empty?
  end

  def stock_suficiente_por_item
    items_vigentes.each do |item|
      next if item.product.blank? || item.cantidad.blank?
      next if item.cantidad <= item.product.stock

      errors.add(:base, "#{item.product.nombre}: quedan #{item.product.stock} unidades, no #{item.cantidad}.")
    end
  end
end
