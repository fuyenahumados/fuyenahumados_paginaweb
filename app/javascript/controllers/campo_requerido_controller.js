import { Controller } from "@hotwired/stimulus"

// Marca (*) roja junto al label de un campo obligatorio — desaparece apenas
// el campo tiene un valor. Se engancha al form-group completo (no a un input
// puntual) y busca el campo con querySelector, así también reacciona a
// valores puestos por JS (dirección guardada, calendario de viernes), que
// disparan sus propios eventos input/change con bubbles: true.
export default class extends Controller {
  static targets = ["marca"]

  connect() {
    this.verificar()
  }

  verificar() {
    const campo = this.element.querySelector("input, select, textarea")
    if (!campo) return

    this.marcaTarget.hidden = campo.value.trim() !== ""
  }
}
