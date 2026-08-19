require "test_helper"

class GeocodificadorServiceTest < ActiveSupport::TestCase
  test "devuelve nil sin llamar a la red si falta la calle o la comuna" do
    assert_nil GeocodificadorService.buscar("", "Las Condes")
    assert_nil GeocodificadorService.buscar("Calle 1", "")
    assert_nil GeocodificadorService.buscar(nil, nil)
  end

  test "Resultado expone encontrada/lat/lng" do
    resultado = GeocodificadorService::Resultado.new(encontrada: true, lat: -33.4, lng: -70.6)
    assert resultado.encontrada
    assert_equal(-33.4, resultado.lat)
    assert_equal(-70.6, resultado.lng)
  end
end
