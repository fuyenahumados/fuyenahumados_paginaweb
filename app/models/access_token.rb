class AccessToken < ApplicationRecord
  validates :token, presence: true, uniqueness: true

  def self.valido?(token)
    exists?(token: token, activo: true)
  end
end
