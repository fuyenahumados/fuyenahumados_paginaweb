import { Controller } from "@hotwired/stimulus"

// Recordatorio en vivo de los campos obligatorios que todavía faltan por
// completar en el checkout — se actualiza mientras el cliente va escribiendo,
// sin esperar a que intente enviar el formulario.
const CAMPOS = [
  { name: "order[nombre_contacto]", label: "Nombre" },
  { name: "order[apellido_contacto]", label: "Apellido" },
  { name: "order[telefono_contacto]", label: "Teléfono" },
  { name: "order[email_contacto]", label: "Email" },
  { name: "order[direccion_calle]", label: "Calle y número" },
  { name: "order[direccion_comuna]", label: "Comuna" },
  { name: "order[fecha_entrega]", label: "Fecha de entrega" }
]

export default class extends Controller {
  static targets = ["aviso", "lista"]

  connect() {
    this.campos = CAMPOS
      .map(({ name, label }) => ({ label, el: this.element.querySelector(`[name="${name}"]`) }))
      .filter(({ el }) => el)

    this.campos.forEach(({ el }) => {
      el.addEventListener("input", () => this.#actualizar())
      el.addEventListener("change", () => this.#actualizar())
    })
    this.#actualizar()
  }

  #actualizar() {
    const faltantes = this.campos.filter(({ el }) => el.value.trim() === "").map(({ label }) => label)

    this.avisoTarget.hidden = faltantes.length === 0
    this.listaTarget.textContent = faltantes.join(", ")
  }
}
