import { Controller } from "@hotwired/stimulus"

// En "Nuevo pedido manual" (admin), al elegir un cliente existente prellena
// sus datos de contacto/dirección principal — igual que direccion-selector en
// el checkout, pero acá el origen del dato es el cliente elegido, no una
// dirección guardada. Elegir "Cliente nuevo" limpia los campos para cargar un
// pedido de invitado, igual que el checkout normal.
export default class extends Controller {
  static targets = ["select", "nombre", "apellido", "telefono", "email", "calle", "comuna", "numeroDepto"]

  aplicar() {
    const opcion = this.selectTarget.selectedOptions[0]
    const datos = opcion ? opcion.dataset : {}

    this.nombreTarget.value = datos.nombre || ""
    this.apellidoTarget.value = datos.apellido || ""
    this.telefonoTarget.value = datos.telefono || ""
    this.emailTarget.value = datos.email || ""
    this.calleTarget.value = datos.calle || ""
    this.comunaTarget.value = datos.comuna || ""
    this.numeroDeptoTarget.value = datos.numeroDepto || ""
  }
}
