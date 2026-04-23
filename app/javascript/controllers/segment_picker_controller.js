import { Controller } from "@hotwired/stimulus"

// Manages a per-segment value picker:
// - Shows a "X / Y selected" count chip
// - Filters the value list when the segment has many values
// - "Select all" / "Clear" toggles
export default class extends Controller {
  static targets = ["count", "checkbox", "filter", "value"]

  connect() {
    this.update()
  }

  update() {
    if (!this.hasCountTarget) return
    const total = this.checkboxTargets.length
    const selected = this.checkboxTargets.filter((cb) => cb.checked).length
    this.countTarget.textContent = `${selected} / ${total}`
  }

  toggleAll(event) {
    const checked = event.currentTarget.dataset.toAll === "select"
    this.checkboxTargets.forEach((cb) => { cb.checked = checked })
    this.update()
  }

  filter() {
    if (!this.hasFilterTarget) return
    const term = this.filterTarget.value.trim().toLowerCase()
    this.valueTargets.forEach((node) => {
      const text = node.textContent.toLowerCase()
      node.hidden = term.length > 0 && !text.includes(term)
    })
  }
}
