import { Controller } from "@hotwired/stimulus"

// Populates phase and task dropdowns when project (and optionally phase) change.
// Expects data-daily-log-form-phases-for-project-url-value and
// data-daily-log-form-tasks-for-project-url-value to be path prefixes (e.g. "/phases_for_project/", "/tasks_for_project/").
export default class extends Controller {
  static targets = ["project", "phase", "task"]
  static values = {
    phasesForProjectUrl: String,
    tasksForProjectUrl: String,
    allPhasesLabel: { type: String, default: "All phases" },
    defaultTaskLabel: { type: String, default: "-- Task --" }
  }

  projectChanged() {
    const projectId = this.projectTarget.value
    this.clearPhaseAndTask()
    if (!projectId) return
    this.fetchPhases(projectId)
    this.fetchTasks(projectId, null)
  }

  phaseChanged() {
    const projectId = this.projectTarget.value
    if (!projectId) return
    const phaseId = this.phaseTarget.value || null
    this.fetchTasks(projectId, phaseId)
  }

  // No-op: task selection is independent of phase.
  taskChanged() {}

  clearPhaseAndTask() {
    if (this.hasPhaseTarget) {
      this.phaseTarget.innerHTML = ""
      this.phaseTarget.value = ""
    }
    if (this.hasTaskTarget) {
      this.taskTarget.innerHTML = `<option value="">${this.defaultTaskLabelValue}</option>`
      this.taskTarget.value = ""
    }
  }

  async fetchPhases(projectId) {
    const url = `${this.phasesForProjectUrlValue}${projectId}`
    const response = await fetch(url, {
      headers: { Accept: "application/json" }
    })
    if (!response.ok) return
    const phases = await response.json()
    const prompt = document.createElement("option")
    prompt.value = ""
    prompt.textContent = this.allPhasesLabelValue
    this.phaseTarget.innerHTML = ""
    this.phaseTarget.appendChild(prompt)
    phases.forEach((p) => {
      const opt = document.createElement("option")
      opt.value = p.id
      opt.textContent = p.name
      this.phaseTarget.appendChild(opt)
    })
  }

  async fetchTasks(projectId, phaseId) {
    let url = `${this.tasksForProjectUrlValue}${projectId}`
    if (phaseId) url += `?phase_id=${encodeURIComponent(phaseId)}`
    const response = await fetch(url, {
      headers: { Accept: "application/json" }
    })
    if (!response.ok) return
    const tasks = await response.json()
    const prompt = document.createElement("option")
    prompt.value = ""
    prompt.textContent = this.defaultTaskLabelValue
    this.taskTarget.innerHTML = ""
    this.taskTarget.appendChild(prompt)
    tasks.forEach((t) => {
      const opt = document.createElement("option")
      opt.value = t.id
      opt.textContent = t.name
      if (t.phase_id != null) opt.dataset.phaseId = String(t.phase_id)
      this.taskTarget.appendChild(opt)
    })
  }
}
