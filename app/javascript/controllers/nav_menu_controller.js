import { Controller } from "@hotwired/stimulus"

// Menú hamburguesa del nav en mobile — despliega/oculta el panel con los
// links y acciones que en desktop van repartidos en .nav-center/.nav-right.
export default class extends Controller {
  static targets = ["panel", "boton"]

  toggle() {
    const abrir = !this.element.classList.contains("menu-abierto")
    this.element.classList.toggle("menu-abierto", abrir)
    this.botonTarget.setAttribute("aria-expanded", abrir)
  }
}
