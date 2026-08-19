import { Controller } from "@hotwired/stimulus"

const SEGUNDOS_INICIALES = 60

// Cuenta regresiva en la pantalla de "confirma por WhatsApp" tras crear un
// pedido — arranca recién cuando el cliente aprieta el link de WhatsApp (no
// apenas carga la página), y pasados los 60s vuelve solo a la home.
export default class extends Controller {
  static targets = ["segundos", "aviso"]
  static values = { redirigirA: String }

  disconnect() {
    clearInterval(this.intervalo)
  }

  iniciar() {
    if (this.intervalo) return

    this.restantes = SEGUNDOS_INICIALES
    this.avisoTarget.hidden = false
    this.#pintar()
    this.intervalo = setInterval(() => this.#tick(), 1000)
  }

  #tick() {
    this.restantes -= 1
    this.#pintar()
    if (this.restantes <= 0) {
      clearInterval(this.intervalo)
      window.location.href = this.redirigirAValue
    }
  }

  #pintar() {
    this.segundosTarget.textContent = this.restantes
  }
}
