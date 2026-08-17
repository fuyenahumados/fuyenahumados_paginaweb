class Product < ApplicationRecord
  has_many :order_items

  enum :categoria, { ahumado: 0 }

  FOTO_EXTENSIONES_VALIDAS = %w[.jpg .jpeg .png .webp].freeze

  validates :nombre, presence: true
  validates :precio, presence: true, numericality: { greater_than: 0 }
  validates :stock,  numericality: { greater_than_or_equal_to: 0 }
  validate  :foto_formato_valido

  scope :activos,        -> { where(activo: true) }
  scope :con_stock,      -> { where("stock > 0") }
  scope :disponibles,    -> { activos.con_stock }

  # Las fotos son archivos estáticos versionados en public/docs/productos/
  # (no se suben dinámicamente: hay que agregarlas al repo y deployar).
  def foto_url
    return nil unless foto_filename.present?

    "/docs/productos/#{foto_filename}"
  end

  private

  def foto_formato_valido
    return unless foto_filename.present?

    unless File.extname(foto_filename).downcase.in?(FOTO_EXTENSIONES_VALIDAS)
      errors.add(:foto_filename, "debe ser un archivo .jpg, .jpeg, .png o .webp")
    end
  end
end
