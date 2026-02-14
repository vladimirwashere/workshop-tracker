import { Controller } from "@hotwired/stimulus"

// Populates phase and task dropdowns when project changes in reports form.
// Similar to daily_log_form_controller but for multi-select reports.
export default class extends Controller {
  static targets = ["project", "phase", "task"]
  static values = {
    phasesForProjectUrl: String,
    tasksForProjectUrl: String,
    allLabel: { type: String, default: "All" }
  }

  async projectChanged() {
    if (!this.hasProjectTarget) return

    const projectId = this.projectTarget.value
    const preferredPhaseId = this.phaseValue()
    const preferredTaskId = this.taskValue()

    await this.syncForProject(projectId, { preferredPhaseId, preferredTaskId })
  }

  async phaseChanged() {
    if (!this.hasProjectTarget || !this.hasPhaseTarget || !this.hasTaskTarget) return

    const projectId = this.projectTarget.value
    const phaseId = this.phaseTarget.value

    if (!projectId) {
      this.clearTask()
      return
    }

    await this.reloadTasks(projectId, phaseId, this.taskValue())
  }

  // No-op: task selection is independent of project/phase.
  taskChanged() {}

  async syncForProject(projectId, { preferredPhaseId = "", preferredTaskId = "" } = {}) {
    if (!projectId) {
      this.clearPhaseAndTask()
      return
    }

    const requestId = this.nextRequestId()
    const phases = await this.fetchPhases(projectId)
    if (!phases || this.isStaleRequest(requestId)) return

    const selectedPhaseId = this.applyPhaseSelection(phases, preferredPhaseId)
    await this.reloadTasks(projectId, selectedPhaseId, preferredTaskId, requestId)
  }

  async reloadTasks(projectId, phaseId, preferredTaskId, requestId = this.nextRequestId()) {
    const tasks = await this.fetchTasks(projectId, phaseId)
    if (!tasks || this.isStaleRequest(requestId)) return

    this.applyTaskSelection(tasks, preferredTaskId)
  }

  clearPhaseAndTask() {
    this.clearPhase()
    this.clearTask()
  }

  clearPhase() {
    if (!this.hasPhaseTarget) return
    this.phaseTarget.innerHTML = `<option value="">${this.allLabelValue}</option>`
  }

  clearTask() {
    if (!this.hasTaskTarget) return
    this.taskTarget.innerHTML = `<option value="">${this.allLabelValue}</option>`
  }

  async fetchPhases(projectId) {
    if (!this.hasPhaseTarget) return null

    try {
      const url = `${this.phasesForProjectUrlValue}${projectId}`
      const response = await fetch(url, { headers: { Accept: "application/json" } })
      if (!response.ok) return null
      return await response.json()
    } catch (err) {
      return null
    }
  }

  async fetchTasks(projectId, phaseId) {
    if (!this.hasTaskTarget) return null

    try {
      let url = `${this.tasksForProjectUrlValue}${projectId}`
      if (phaseId) url += `?phase_id=${encodeURIComponent(phaseId)}`
      const response = await fetch(url, { headers: { Accept: "application/json" } })
      if (!response.ok) return null
      return await response.json()
    } catch (err) {
      return null
    }
  }

  applyPhaseSelection(phases, preferredPhaseId) {
    this.clearPhase()

    phases.forEach((phase) => {
      const opt = document.createElement("option")
      opt.value = String(phase.id)
      opt.textContent = phase.name
      opt.dataset.projectId = String(phase.project_id || this.projectTarget.value)
      this.phaseTarget.appendChild(opt)
    })

    const selected = this.hasOption(this.phaseTarget, preferredPhaseId) ? String(preferredPhaseId) : ""
    this.phaseTarget.value = selected
    return selected
  }

  applyTaskSelection(tasks, preferredTaskId) {
    this.clearTask()

    tasks.forEach((task) => {
      const opt = document.createElement("option")
      opt.value = String(task.id)
      opt.textContent = task.name
      opt.dataset.projectId = String(task.project_id)
      if (task.phase_id != null) opt.dataset.phaseId = String(task.phase_id)
      this.taskTarget.appendChild(opt)
    })

    this.taskTarget.value = this.hasOption(this.taskTarget, preferredTaskId) ? String(preferredTaskId) : ""
  }

  phaseValue() {
    return this.hasPhaseTarget ? this.phaseTarget.value : ""
  }

  taskValue() {
    return this.hasTaskTarget ? this.taskTarget.value : ""
  }

  hasOption(select, value) {
    if (!value) return false
    return Array.from(select.options).some((option) => option.value === String(value))
  }

  nextRequestId() {
    this.requestIdValue = (this.requestIdValue || 0) + 1
    return this.requestIdValue
  }

  isStaleRequest(requestId) {
    return requestId !== this.requestIdValue
  }

}
