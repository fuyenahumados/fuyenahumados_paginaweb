import { Controller } from "@hotwired/stimulus"

// Al elegir una dirección guardada, rellena los campos de calle/comuna/depto
// del formulario — que igual quedan editables por si el cliente quiere ajustarlos.
export default class extends Controller {
  static targets = ["calle", "comuna", "numeroDepto"]

  // Si ya hay una dirección marcada por defecto al cargar la página, sus datos
  // tienen que reflejarse en los campos desde el primer momento — no solo
  // cuando el cliente hace click en la opción (para no arriesgar que, si
  // cambia de dirección, se le olvide que la comuna quedó de la anterior).
  connect() {
    const marcada = this.element.querySelector('input[name="direccion_guardada"]:checked')
    if (marcada) this.#aplicar(marcada.dataset)
  }

  seleccionar(evento) {
    this.#aplicar(evento.currentTarget.dataset)
  }

  #aplicar({ calle, comuna, numeroDepto }) {
    this.calleTarget.value = calle
    this.comunaTarget.value = comuna
    if (this.hasNumeroDeptoTarget) this.numeroDeptoTarget.value = numeroDepto || ""

    this.calleTarget.dispatchEvent(new Event("input", { bubbles: true }))
    this.comunaTarget.dispatchEvent(new Event("change", { bubbles: true }))
    if (this.hasNumeroDeptoTarget) this.numeroDeptoTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }
}
