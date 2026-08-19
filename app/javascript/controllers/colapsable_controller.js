import { Controller } from "@hotwired/stimulus"

// Sección colapsable genérica: el título queda siempre visible, el resto del
// contenido se muestra/oculta con un botón (ej. "Resumen de tu pedido").
export default class extends Controller {
  static targets = ["contenido", "boton"]

  toggle() {
    const abrir = this.contenidoTarget.hidden
    this.contenidoTarget.hidden = !abrir
    this.botonTarget.setAttribute("aria-expanded", abrir)
  }
}
