class Direccion < ApplicationRecord
  belongs_to :user

  COMUNAS = [ "Lo Barnechea", "Las Condes", "Vitacura", "Providencia", "La Reina" ].freeze

  validates :etiqueta, presence: true
  validates :comuna, presence: true, inclusion: { in: COMUNAS }
  validates :calle, presence: true

  before_save :gestionar_principal
  after_destroy :promover_otra_a_principal

  def direccion_completa
    [ calle, numero_depto, comuna ].reject(&:blank?).join(", ")
  end

  private

  def gestionar_principal
    # La primera (o única) dirección de un usuario siempre es la principal.
    self.principal = true if user.direcciones.where.not(id: id).none?
    user.direcciones.where.not(id: id).update_all(principal: false) if principal?
  end

  def promover_otra_a_principal
    return if user.direcciones.where(principal: true).exists?

    user.direcciones.order(:created_at).first&.update_column(:principal, true)
  end
end
