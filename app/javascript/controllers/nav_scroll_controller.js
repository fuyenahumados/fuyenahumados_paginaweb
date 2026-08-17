import { Controller } from "@hotwired/stimulus"

const UMBRAL = 10

// Le agrega la clase "scrolled" al nav apenas se hace scroll — se usa en la
// home para que el nav pase de transparente (sobre el hero) a semi-opaco.
export default class extends Controller {
  connect() {
    this.alScrollear = () => {
      this.element.classList.toggle("scrolled", window.scrollY > UMBRAL)
    }
    this.alScrollear()
    window.addEventListener("scroll", this.alScrollear, { passive: true })
  }

  disconnect() {
    window.removeEventListener("scroll", this.alScrollear)
  }
}
