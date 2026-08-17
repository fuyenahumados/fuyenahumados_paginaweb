class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :orders, dependent: :destroy
  has_many :direcciones, dependent: :destroy
  accepts_nested_attributes_for :direcciones

  enum :role, { cliente: 0, admin: 1 }

  TELEFONO_FORMATO = /\A\+?[\d\s]{8,15}\z/

  validates :nombre, presence: true
  validates :apellido, presence: true
  validates :telefono, presence: true, format: { with: TELEFONO_FORMATO, message: "no es un número de teléfono válido" }

  def nombre_completo
    "#{nombre} #{apellido}"
  end

  def direccion_principal
    direcciones.find_by(principal: true) || direcciones.first
  end
end
