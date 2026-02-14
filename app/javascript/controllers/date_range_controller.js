import { Controller } from "@hotwired/stimulus"

// Auto-fills end date from start date when end date is empty.
export default class extends Controller {
  static targets = ["startDate", "endDate"]

  fillEnd() {
    if (!this.hasEndDateTarget) return
    if (this.endDateTarget.value) return

    this.endDateTarget.value = this.startDateTarget.value
  }
}
