class Resena < ApplicationRecord
  belongs_to :user
  belongs_to :product

  validates :calificacion, presence: true, inclusion: { in: 1..5 }
  validates :user_id, uniqueness: { scope: :product_id, message: "ya reseñó este producto" }
  validate :cliente_compro_el_producto, on: :create

  private

  def cliente_compro_el_producto
    return if user.blank? || product.blank?

    errors.add(:base, "Solo puedes reseñar productos que hayas comprado") unless user.compro?(product)
  end
end
