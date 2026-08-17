import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  aplicar() {
    this.element.requestSubmit()
  }
}
