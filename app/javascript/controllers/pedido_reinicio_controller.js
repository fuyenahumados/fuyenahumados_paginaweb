import { Controller } from "@hotwired/stimulus"

const SEGUNDOS_ESPERA = 60

// Pantalla de "confirma por WhatsApp" tras crear un pedido.
// - Si el cliente no aprieta ningún botón/link de WhatsApp en 60s, esta misma
//   pestaña lo redirige sola a WhatsApp (para que sí o sí termine de confirmar).
// - Si lo aprieta antes, en cambio arranca una cuenta regresiva de 60s que
//   trae de vuelta a la home (se asume que ya alcanzó a escribir el mensaje).
export default class extends Controller {
  static targets = ["segundos", "aviso"]
  static values = { redirigirA: String, whatsapp: String }

  connect() {
    this.esperaId = setTimeout(() => this.#irAWhatsapp(), SEGUNDOS_ESPERA * 1000)
  }

  disconnect() {
    clearTimeout(this.esperaId)
    clearInterval(this.intervalo)
  }

  iniciar() {
    clearTimeout(this.esperaId)
    if (this.intervalo) return

    this.restantes = SEGUNDOS_ESPERA
    this.avisoTarget.hidden = false
    this.#pintar()
    this.intervalo = setInterval(() => this.#tick(), 1000)
  }

  #irAWhatsapp() {
    window.location.href = this.whatsappValue
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
