import { Controller } from "@hotwired/stimulus"

// Toggles between inc-VAT and ex-VAT unit cost input.
// A single visible input + inline dropdown; hidden fields carry both values to the server.
export default class extends Controller {
  static targets = ["incInput", "exInput", "visibleInput", "modeSelect", "preview"]
  static values = { rate: { type: Number, default: 0.21 } }

  connect() {
    this.compute()
  }

  get mode() {
    return this.modeSelectTarget.value
  }

  // Called when the user switches the dropdown between inc/ex
  modeChanged() {
    const multiplier = 1 + this.rateValue
    const current = parseFloat(this.visibleInputTarget.value)

    if (!isNaN(current) && current >= 0) {
      // Convert the displayed value to the new mode
      if (this.mode === "inc") {
        // Was ex, now inc
        this.visibleInputTarget.value = (current * multiplier).toFixed(2)
      } else {
        // Was inc, now ex
        this.visibleInputTarget.value = (current / multiplier).toFixed(2)
      }
    }
    this.compute()
  }

  // Called on every keystroke in the visible input
  compute() {
    const rate = this.rateValue
    const multiplier = 1 + rate
    const val = parseFloat(this.visibleInputTarget.value)

    if (isNaN(val) || val < 0) {
      this.previewTarget.textContent = ""
      return
    }

    if (this.mode === "inc") {
      const ex = (val / multiplier).toFixed(2)
      this.incInputTarget.value = val
      this.exInputTarget.value = ex
      this.previewTarget.textContent = this.previewTarget.dataset.templateEx.replace("%{amount}", ex)
    } else {
      const inc = (val * multiplier).toFixed(2)
      this.exInputTarget.value = val
      this.incInputTarget.value = inc
      this.previewTarget.textContent = this.previewTarget.dataset.templateInc.replace("%{amount}", inc)
    }
  }

  // Called when the VAT rate dropdown changes
  rateChanged(event) {
    this.rateValue = parseFloat(event.currentTarget.value) || 0
    this.compute()
  }
}
