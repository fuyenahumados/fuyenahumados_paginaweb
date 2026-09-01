import { Controller } from "@hotwired/stimulus"

// Agrega/quita líneas de producto en "Nuevo pedido manual" (admin) sin
// recargar la página — clona el <template> con los fields_for de
// order_items_attributes (mismo truco que usan gemas como cocoon: reemplazar
// un placeholder de índice por uno único al clonar). El total mostrado acá es
// solo una ayuda visual en vivo; el total real se recalcula siempre en el
// servidor a partir de los OrderItems guardados.
export default class extends Controller {
  static targets = ["filas", "template", "fila", "subtotal", "total"]

  connect() {
    this.actualizar()
  }

  agregar() {
    const indice = new Date().getTime()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, indice)
    this.filasTarget.insertAdjacentHTML("beforeend", html)
    this.actualizar()
  }

  quitar(evento) {
    evento.target.closest("[data-pedido-items-target='fila']").remove()
    this.actualizar()
  }

  actualizar() {
    let total = 0

    this.filaTargets.forEach((fila) => {
      const select = fila.querySelector("select")
      const cantidad = parseInt(fila.querySelector("input[type='number']").value, 10) || 0
      const precio = parseInt(select?.selectedOptions[0]?.dataset.precio || 0, 10)
      const subtotal = precio * cantidad

      fila.querySelector("[data-pedido-items-target='subtotal']").textContent = this.#formatear(subtotal)
      total += subtotal
    })

    this.totalTarget.textContent = this.#formatear(total)
  }

  #formatear(monto) {
    return `$${monto.toLocaleString("es-CL")}`
  }
}
