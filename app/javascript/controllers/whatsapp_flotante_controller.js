import { Controller } from "@hotwired/stimulus"

const UMBRAL = 200

// El botón flotante de WhatsApp arranca oculto y aparece recién cuando el
// usuario hace scroll hacia abajo (a pedido de Joaquín, para que no tape el
// hero apenas se carga la página) — mismo patrón que nav_scroll_controller.js.
export default class extends Controller {
  connect() {
    this.alScrollear = () => {
      this.element.classList.toggle("visible", window.scrollY > UMBRAL)
    }
    this.alScrollear()
    window.addEventListener("scroll", this.alScrollear, { passive: true })
  }

  disconnect() {
    window.removeEventListener("scroll", this.alScrollear)
  }
}
