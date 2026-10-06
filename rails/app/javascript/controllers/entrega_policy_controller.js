import { Controller } from "@hotwired/stimulus"

// Copies the selected supplier's current delivery minimum into the line below.
export default class extends Controller {
  static targets = ["select", "summary"]

  connect() {
    this.refresh()
  }

  refresh() {
    const option = this.selectTarget.selectedOptions[0]
    const entrega = option?.value ? option.dataset.entrega : ""
    if (!entrega) {
      this.summaryTarget.textContent = ""
      this.summaryTarget.classList.add("d-none")
      return
    }

    this.summaryTarget.textContent = entrega
    this.summaryTarget.classList.remove("d-none")
  }
}
