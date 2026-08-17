# Política de costo de envío: monto fijo, gratis desde un subtotal de productos
# determinado (el envío mismo no cuenta para ese umbral).
class CostoEnvio
  MONTO = 2_000
  GRATIS_DESDE = 40_000

  def self.calcular(subtotal_productos)
    gratis?(subtotal_productos) ? 0 : MONTO
  end

  def self.gratis?(subtotal_productos)
    subtotal_productos >= GRATIS_DESDE
  end
end
