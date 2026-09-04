import { Controller } from "@hotwired/stimulus"

// Toggles entrada item fields like the Streamlit form:
// - "Otro (escribir nuevo)" → new-item fields + optional cable details
// - existing cable → punta/longitud/color
// - existing non-cable → cantidad only
export default class extends Controller {
  static targets = [
    "articleSelect",
    "newFields",
    "cableFields",
    "quantityFields",
    "esCableCheckbox"
  ]

  connect() {
    this.refresh()
  }

  refresh() {
    const selected = this.articleSelectTarget.selectedOptions[0]
    const isNew = selected?.value === "__new__"
    const isCableExisting = selected?.dataset.esCable === "true"
    const isCableNew = this.hasEsCableCheckboxTarget && this.esCableCheckboxTarget.checked
    const showCable = isNew ? isCableNew : isCableExisting

    this.toggle(this.newFieldsTarget, isNew)
    this.toggle(this.cableFieldsTarget, showCable)
    this.toggle(this.quantityFieldsTarget, !showCable && (isNew || selected?.value))
  }

  toggle(element, show) {
    element.classList.toggle("d-none", !show)
    element.querySelectorAll("input, select, textarea").forEach((el) => {
      el.disabled = !show
    })
  }
}
