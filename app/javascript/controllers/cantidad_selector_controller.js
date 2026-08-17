import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]
  static values = { max: Number }

  sumar() {
    this.#actualizar(this.#valor + 1)
  }

  restar() {
    this.#actualizar(this.#valor - 1)
  }

  corregir() {
    if (this.inputTarget.value === "") return
    this.#actualizar(this.#valor)
  }

  get #valor() {
    return parseInt(this.inputTarget.value, 10) || 1
  }

  #actualizar(valor) {
    const max = this.maxValue || Infinity
    this.inputTarget.value = Math.min(Math.max(valor, 1), max)
  }
}
