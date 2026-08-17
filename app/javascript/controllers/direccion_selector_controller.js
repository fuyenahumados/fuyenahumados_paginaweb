import { Controller } from "@hotwired/stimulus"

// Al elegir una dirección guardada, rellena los campos de calle/comuna del
// formulario — que igual quedan editables por si el cliente quiere ajustarlos.
export default class extends Controller {
  static targets = ["calle", "comuna"]

  seleccionar(evento) {
    const { calle, comuna } = evento.currentTarget.dataset
    this.calleTarget.value = calle
    this.comunaTarget.value = comuna
  }
}
