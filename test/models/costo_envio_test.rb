require "test_helper"

class CostoEnvioTest < ActiveSupport::TestCase
  test "cobra el monto fijo bajo el umbral" do
    assert_equal CostoEnvio::MONTO, CostoEnvio.calcular(CostoEnvio::GRATIS_DESDE - 1)
  end

  test "es gratis justo en el umbral" do
    assert_equal 0, CostoEnvio.calcular(CostoEnvio::GRATIS_DESDE)
  end

  test "es gratis sobre el umbral" do
    assert_equal 0, CostoEnvio.calcular(CostoEnvio::GRATIS_DESDE + 10_000)
  end

  test "gratis? refleja el mismo umbral que calcular" do
    assert_not CostoEnvio.gratis?(CostoEnvio::GRATIS_DESDE - 1)
    assert CostoEnvio.gratis?(CostoEnvio::GRATIS_DESDE)
  end
end
