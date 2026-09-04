import { Controller } from "@hotwired/stimulus"

// Shows Centro de Costo / Nombre Obra metrics when a project is selected
// (parity with Streamlit render_project_selector).
export default class extends Controller {
  static targets = ["select", "metrics", "cc", "obra"]

  connect() {
    this.refresh()
  }

  refresh() {
    const option = this.selectTarget.selectedOptions[0]
    if (!option?.value) {
      this.metricsTarget.classList.add("d-none")
      return
    }

    this.ccTarget.textContent = option.dataset.cc || "—"
    this.obraTarget.textContent = option.dataset.obra || "—"
    this.metricsTarget.classList.remove("d-none")
  }
}
