import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["phaseRow", "phaseTasks"]

  connect() {
    this.phaseRowTargets.forEach((row) => {
      row.dataset.expanded = "true"
      row.setAttribute("aria-expanded", "true")
    })
    this.phaseTasksTargets.forEach((taskRow) => {
      taskRow.dataset.expanded = "true"
    })
  }

  toggle(event) {
    const phaseRow = event.currentTarget
    const phaseId = String(phaseRow.dataset.phaseId)
    const isExpanded = phaseRow.dataset.expanded === "true"

    const taskRows = this.phaseTasksTargets.filter(
      el => String(el.dataset.phaseId) === phaseId
    )

    taskRows.forEach((row) => {
      if (isExpanded) {
        row.classList.add("hidden")
        row.dataset.expanded = "false"
      } else {
        row.classList.remove("hidden")
        row.dataset.expanded = "true"
      }
    })

    phaseRow.dataset.expanded = isExpanded ? "false" : "true"
    phaseRow.setAttribute("aria-expanded", isExpanded ? "false" : "true")

    // Rotate the chevron icon
    const toggleIcon = phaseRow.querySelector(".toggle-icon")
    if (toggleIcon) {
      if (isExpanded) {
        toggleIcon.innerHTML = '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path></svg>'
      } else {
        toggleIcon.innerHTML = '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>'
      }
    }
  }

  stopProp(event) {
    event.stopPropagation()
  }
}
