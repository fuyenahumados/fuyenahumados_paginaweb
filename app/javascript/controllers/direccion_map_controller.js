import { Controller } from "@hotwired/stimulus"
import * as L from "leaflet"

const CHILE_CENTRO = [-33.45, -70.62]
const PIN_SVG = `<svg viewBox="0 0 24 24" width="32" height="32">
  <path d="M12 2C7.6 2 4 5.6 4 10c0 6 8 12 8 12s8-6 8-12c0-4.4-3.6-8-8-8Z" fill="#b8934f" stroke="#081f2e" stroke-width="1"/>
  <circle cx="12" cy="10" r="3" fill="#fff"/>
</svg>`

export default class extends Controller {
  static targets = ["map", "calle", "comuna", "lat", "lng"]
  static values = { lat: Number, lng: Number }

  connect() {
    const tieneCoords = this.hasLatValue && this.latValue && this.hasLngValue && this.lngValue
    const inicio = tieneCoords ? [this.latValue, this.lngValue] : CHILE_CENTRO

    this.map = L.map(this.mapTarget).setView(inicio, tieneCoords ? 16 : 10)

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 19,
      attribution: "&copy; colaboradores de OpenStreetMap"
    }).addTo(this.map)

    const pinIcon = L.divIcon({
      html: PIN_SVG,
      className: "mapa-pin",
      iconSize: [32, 32],
      iconAnchor: [16, 32]
    })

    this.marker = L.marker(inicio, { draggable: true, icon: pinIcon, opacity: tieneCoords ? 1 : 0.4 }).addTo(this.map)
    this.marker.on("dragend", () => this.#guardarCoords(this.marker.getLatLng()))
  }

  disconnect() {
    this.map?.remove()
  }

  buscar() {
    clearTimeout(this.timeout)
    const consulta = this.calleTarget.value.trim()
    if (consulta.length < 5) return

    this.timeout = setTimeout(() => this.#geocodificar(consulta), 700)
  }

  async #geocodificar(consulta) {
    const comuna = this.hasComunaTarget ? this.comunaTarget.value : ""
    const query = encodeURIComponent(`${consulta}, ${comuna}, Chile`)

    try {
      const respuesta = await fetch(`https://nominatim.openstreetmap.org/search?format=json&limit=1&countrycodes=cl&q=${query}`)
      const resultados = await respuesta.json()
      if (!resultados[0]) return

      const punto = { lat: parseFloat(resultados[0].lat), lng: parseFloat(resultados[0].lon) }
      this.marker.setLatLng(punto).setOpacity(1)
      this.map.setView(punto, 16)
      this.#guardarCoords(punto)
    } catch {
      // Si falla la geocodificación, el cliente igual puede mover el pin a mano.
    }
  }

  #guardarCoords({ lat, lng }) {
    this.latTarget.value = lat
    this.lngTarget.value = lng
  }
}
