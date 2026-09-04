import { Controller } from "@hotwired/stimulus"

// Optional date range filter (parity with Streamlit "Filtrar por rango de fechas").
export default class extends Controller {
  static targets = ["fields", "checkbox"]

  connect() {
    this.refresh()
  }

  refresh() {
    const enabled = this.checkboxTarget.checked
    this.fieldsTarget.classList.toggle("d-none", !enabled)
    this.fieldsTarget.querySelectorAll("input").forEach((el) => {
      el.disabled = !enabled
    })
  }
}
