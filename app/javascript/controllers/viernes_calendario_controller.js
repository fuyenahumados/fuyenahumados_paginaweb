import { Controller } from "@hotwired/stimulus"

const DIAS_SEMANA = ["L", "M", "M", "J", "V", "S", "D"]
const MESES_ES = [
  "enero", "febrero", "marzo", "abril", "mayo", "junio",
  "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"
]

// Calendario que solo permite seleccionar viernes (único día de despacho).
// El resto de los días se muestran en rojo y no se pueden seleccionar.
// Si se pasa `min`, los viernes anteriores a esa fecha tampoco son seleccionables
// (se usa en el checkout para no poder pedir despacho para "hoy mismo").
export default class extends Controller {
  static targets = ["input", "display", "popup", "grid", "label"]
  static values = { min: String }

  connect() {
    const inicio = this.inputTarget.value || this.minValue
    this.mesActual = inicio ? this.#parsearFecha(inicio) : new Date()
    this.#render()
    this.cerrarAlClickAfuera = (evento) => {
      if (!this.element.contains(evento.target)) this.cerrar()
    }
  }

  disconnect() {
    document.removeEventListener("click", this.cerrarAlClickAfuera)
  }

  toggle() {
    this.popupTarget.classList.contains("abierto") ? this.cerrar() : this.abrir()
  }

  abrir() {
    this.popupTarget.classList.add("abierto")
    document.addEventListener("click", this.cerrarAlClickAfuera)
  }

  cerrar() {
    this.popupTarget.classList.remove("abierto")
    document.removeEventListener("click", this.cerrarAlClickAfuera)
  }

  mesAnterior(evento) {
    evento.preventDefault()
    this.mesActual = new Date(this.mesActual.getFullYear(), this.mesActual.getMonth() - 1, 1)
    this.#render()
  }

  mesSiguiente(evento) {
    evento.preventDefault()
    this.mesActual = new Date(this.mesActual.getFullYear(), this.mesActual.getMonth() + 1, 1)
    this.#render()
  }

  seleccionar(evento) {
    evento.preventDefault()
    const fecha = evento.currentTarget.dataset.fecha
    this.inputTarget.value = fecha
    this.displayTarget.textContent = this.#formatearDisplay(this.#parsearFecha(fecha))
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.cerrar()
    this.#render()
  }

  #render() {
    const año = this.mesActual.getFullYear()
    const mes = this.mesActual.getMonth()
    this.labelTarget.textContent = `${MESES_ES[mes]} ${año}`

    const primerDiaMes = new Date(año, mes, 1)
    const offset = (primerDiaMes.getDay() + 6) % 7 // lunes = 0 ... domingo = 6
    const diasEnMes = new Date(año, mes + 1, 0).getDate()
    const minimo = this.minValue ? this.#parsearFecha(this.minValue) : null
    const seleccionada = this.inputTarget.value || null

    let html = DIAS_SEMANA.map((d) => `<div class="viernes-calendario-cabecera">${d}</div>`).join("")
    for (let i = 0; i < offset; i++) html += `<div class="viernes-calendario-vacio"></div>`

    for (let dia = 1; dia <= diasEnMes; dia++) {
      const fecha = new Date(año, mes, dia)
      const iso = this.#formatearISO(fecha)
      const esViernes = fecha.getDay() === 5
      const esMuyPronto = minimo && fecha < minimo
      const seleccionable = esViernes && !esMuyPronto

      const clases = ["viernes-calendario-dia"]
      if (!esViernes) clases.push("no-viernes")
      else if (esMuyPronto) clases.push("viernes-no-disponible")
      else clases.push("viernes-disponible")
      if (iso === seleccionada) clases.push("seleccionado")

      if (seleccionable) {
        html += `<button type="button" class="${clases.join(" ")}" data-fecha="${iso}" data-action="viernes-calendario#seleccionar">${dia}</button>`
      } else {
        html += `<span class="${clases.join(" ")}" aria-disabled="true">${dia}</span>`
      }
    }

    this.gridTarget.innerHTML = html
  }

  #parsearFecha(iso) {
    const [y, m, d] = iso.split("-").map(Number)
    return new Date(y, m - 1, d)
  }

  #formatearISO(fecha) {
    const y = fecha.getFullYear()
    const m = String(fecha.getMonth() + 1).padStart(2, "0")
    const d = String(fecha.getDate()).padStart(2, "0")
    return `${y}-${m}-${d}`
  }

  #formatearDisplay(fecha) {
    return `Viernes ${String(fecha.getDate()).padStart(2, "0")}/${String(fecha.getMonth() + 1).padStart(2, "0")}/${fecha.getFullYear()}`
  }
}
