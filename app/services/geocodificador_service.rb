require "net/http"
require "json"

# Verifica contra Nominatim (OpenStreetMap) si una dirección (calle + comuna)
# existe de verdad, antes de aceptar un pedido. Si el servicio de geocodificación
# no responde (red caída, timeout, rate limit) devuelve nil a propósito — un pedido
# real no debe rechazarse por una falla de un servicio externo, solo cuando
# Nominatim respondió y confirmó que no encontró nada.
class GeocodificadorService
  Resultado = Struct.new(:encontrada, :lat, :lng, keyword_init: true)

  USER_AGENT = "FuyenAhumados/1.0 (#{CONTACTO[:email]})".freeze

  def self.buscar(calle, comuna)
    return nil if calle.blank? || comuna.blank?

    resultado = consultar(calle, comuna)
    return resultado if resultado.nil? || resultado.encontrada

    # Muchas calles (sobre todo pasajes o calles nuevas) no tienen el número de
    # casa cargado en OpenStreetMap aunque la calle sí exista — antes de rechazar
    # el pedido, reintentamos sin el número. Si esto encuentra la calle, igual
    # guardamos las coordenadas de la calle (el pin queda editable en el mapa).
    calle_sin_numero = calle.sub(/\s*\d+\s*\z/, "").strip
    return resultado if calle_sin_numero.blank? || calle_sin_numero == calle

    consultar(calle_sin_numero, comuna)
  end

  def self.consultar(calle, comuna)
    uri = URI("https://nominatim.openstreetmap.org/search")
    # Query estructurada (street/city/country) en vez de un solo string libre:
    # Nominatim la interpreta de forma mucho más confiable para direcciones
    # chilenas, la comuna pesa como filtro real en vez de ser una palabra más
    # dentro del texto libre.
    uri.query = URI.encode_www_form(
      street: calle,
      city: comuna,
      country: "Chile",
      format: "json",
      limit: 1,
      countrycodes: "cl"
    )

    respuesta = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 3, read_timeout: 3) do |http|
      http.request(Net::HTTP::Get.new(uri, "User-Agent" => USER_AGENT))
    end

    return nil unless respuesta.is_a?(Net::HTTPSuccess)

    resultados = JSON.parse(respuesta.body)
    return Resultado.new(encontrada: false) if resultados.empty?

    primero = resultados.first
    Resultado.new(encontrada: true, lat: primero["lat"].to_f, lng: primero["lon"].to_f)
  rescue StandardError
    nil
  end
  private_class_method :consultar
end
