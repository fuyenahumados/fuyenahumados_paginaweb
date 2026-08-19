import { Controller } from "@hotwired/stimulus"

// Refleja en vivo, en la sección "Resumen de tu pedido", los datos que el
// cliente va completando arriba en el formulario (dirección, fecha de
// despacho e instrucciones) — sin esperar a que envíe el formulario.
export default class extends Controller {
  static targets = [
    "calle", "comuna", "numeroDepto", "notas",
    "resumenDireccion", "resumenFecha", "resumenNotasFila", "resumenNotasTexto"
  ]

  connect() {
    this.actualizarDireccion()
    this.actualizarNotas()
    const fechaInput = this.element.querySelector('[name="order[fecha_entrega]"]')
    if (fechaInput) this.#pintarFecha(fechaInput.value)
  }

  actualizarDireccion() {
    const calle = this.calleTarget.value.trim()
    const comuna = this.comunaTarget.value
    const numeroDepto = this.hasNumeroDeptoTarget ? this.numeroDeptoTarget.value.trim() : ""
    this.resumenDireccionTarget.textContent = calle && comuna
      ? [calle, numeroDepto, comuna].filter(Boolean).join(", ")
      : "—"
  }

  actualizarFecha(evento) {
    this.#pintarFecha(evento.target.value)
  }

  actualizarNotas() {
    const notas = this.notasTarget.value.trim()
    this.resumenNotasFilaTarget.hidden = notas === ""
    this.resumenNotasTextoTarget.textContent = notas
  }

  #pintarFecha(iso) {
    if (!iso) {
      this.resumenFechaTarget.textContent = "—"
      return
    }
    const [año, mes, dia] = iso.split("-")
    this.resumenFechaTarget.textContent = `Viernes ${dia}/${mes}/${año}`
  }
}
