import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  cerrar() {
    this.element.remove()
  }

  cerrarSiOverlay(event) {
    if (event.target === this.element) this.cerrar()
  }

  cerrarConEscape(event) {
    if (event.key === "Escape") this.cerrar()
  }
}
