class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :cantidad,        presence: true, numericality: { greater_than: 0 }
  validates :precio_unitario, presence: true, numericality: { greater_than: 0 }

  def subtotal
    cantidad * precio_unitario
  end
end
