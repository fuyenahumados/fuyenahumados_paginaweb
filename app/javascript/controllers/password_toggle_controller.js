import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "eyeOpen", "eyeSlash"]

  connect() {
    this.#actualizar(false)
  }

  toggle() {
    const willReveal = this.inputTarget.type === "password"
    this.inputTarget.type = willReveal ? "text" : "password"
    this.#actualizar(willReveal)
  }

  #actualizar(visible) {
    this.eyeOpenTarget.style.display = visible ? "block" : "none"
    this.eyeSlashTarget.style.display = visible ? "none" : "block"
  }
}
