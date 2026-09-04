import { Controller } from "@hotwired/stimulus"

// For salidas: existing articles only.
// Cable → show available puntas for that article.
// Non-cable → show cantidad capped at stock.
export default class extends Controller {
  static targets = [
    "articleSelect",
    "cableFields",
    "quantityFields",
    "puntaSelect",
    "cantidadInput",
    "stockHint",
    "noPuntasWarning"
  ]

  connect() {
    this.refresh()
  }

  refresh() {
    const selected = this.articleSelectTarget.selectedOptions[0]
    if (!selected?.value) {
      this.toggle(this.cableFieldsTarget, false)
      this.toggle(this.quantityFieldsTarget, false)
      this.noPuntasWarningTarget?.classList.add("d-none")
      return
    }

    const isCable = selected.dataset.esCable === "true"
    this.toggle(this.cableFieldsTarget, isCable)
    this.toggle(this.quantityFieldsTarget, !isCable)

    if (isCable) {
      this.filterPuntas(selected.value)
    } else {
      const stock = parseFloat(selected.dataset.stock || "0")
      if (this.hasCantidadInputTarget) {
        this.cantidadInputTarget.max = stock > 0 ? stock : 0
        this.cantidadInputTarget.value = ""
      }
      if (this.hasStockHintTarget) {
        this.stockHintTarget.textContent = `Máximo disponible: ${stock}`
      }
    }
  }

  filterPuntas(articuloId) {
    let visible = 0
    Array.from(this.puntaSelectTarget.options).forEach((opt) => {
      if (!opt.value) {
        opt.hidden = false
        return
      }
      const match = opt.dataset.articuloId === articuloId
      opt.hidden = !match
      if (match) visible += 1
    })
    this.puntaSelectTarget.value = ""
    this.noPuntasWarningTarget?.classList.toggle("d-none", visible > 0)
  }

  toggle(element, show) {
    element.classList.toggle("d-none", !show)
    element.querySelectorAll("input, select, textarea").forEach((el) => {
      el.disabled = !show
    })
  }
}
