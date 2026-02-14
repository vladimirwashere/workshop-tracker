import { Controller } from "@hotwired/stimulus"
import * as d3 from "d3"
import { formatDate } from "helpers/format_date"
import { showToast } from "helpers/toast"
import { csrfToken } from "helpers/csrf_token"
import { escapeHtml } from "helpers/escape_html"

// Period presets (days): single source for window and zoom. 7 → ~40px/day, 365 → ~5px/day.
const PERIOD_DAYS = [7, 14, 30, 90, 180, 365]
const MS_PER_DAY = 24 * 60 * 60 * 1000

function pixelsPerDayFromPeriodDays(periodDays) {
  const minPpd = 5
  const maxPpd = 40
  const t = (periodDays - 7) / (365 - 7)
  return maxPpd - t * (maxPpd - minPpd)
}

export default class extends Controller {
  static targets = ["chart", "periodSlider", "periodLabel", "projectDropdownTrigger", "projectDropdownPanel", "projectDropdownSummary", "projectDropdownWrapper", "projectCheckbox", "tooltip"]
  static values = {
    dataUrl: String,
    updateUrl: String,
    canEdit: { type: Boolean, default: false },
    period: { type: Number, default: 90 },
    allProjects: String,
    projectsSelected: String,
    periodLabels: Array
  }

  connect() {
    this.margin = { top: 40, right: 30, bottom: 30, left: 220 }
    this.rowHeight = 32
    this.barHeight = 22
    this.anchorDate = null
    const periodNum = parseInt(this.periodValue, 10)
    if (Number.isNaN(periodNum) || !PERIOD_DAYS.includes(periodNum)) {
      this.periodValue = 90
    } else {
      this.periodValue = periodNum
    }
    this.syncPeriodSlider()
    this.fetchAndRender(false)
  }

  syncPeriodSlider() {
    if (this.hasPeriodSliderTarget) {
      const index = PERIOD_DAYS.indexOf(this.periodValue)
      const sliderValue = index >= 0 ? index : 3
      this.periodSliderTarget.value = String(sliderValue)
    }
    this.updatePeriodLabel()
  }

  updatePeriodLabel() {
    if (!this.hasPeriodLabelTarget) return
    const index = PERIOD_DAYS.indexOf(this.periodValue)
    if (index >= 0 && this.hasPeriodLabelsValue && this.periodLabelsValue.length > index) {
      this.periodLabelTarget.textContent = this.periodLabelsValue[index]
    } else {
      const labels = { 7: "1 week", 14: "2 weeks", 30: "1 month", 90: "3 months", 180: "6 months", 365: "1 year" }
      this.periodLabelTarget.textContent = labels[this.periodValue] || "3 months"
    }
  }

  disconnect() {
    if (this._fetchController) this._fetchController.abort()
  }

  buildDataUrl(sendDateParams) {
    const base = this.dataUrlValue
    const params = new URLSearchParams()
    if (this.hasProjectCheckboxTarget) {
      const selected = this.projectCheckboxTargets.filter(cb => cb.checked).map(cb => cb.value)
      selected.forEach(id => params.append("project_ids[]", id))
    }
    if (sendDateParams && this.anchorDate) {
      const from = this.anchorDate.toISOString().split("T")[0]
      const end = new Date(this.anchorDate.getTime() + this.periodValue * MS_PER_DAY)
      params.set("date_from", from)
      params.set("date_to", end.toISOString().split("T")[0])
    }
    const qs = params.toString()
    return qs ? `${base}?${qs}` : base
  }

  fetchAndRender(sendDateParams) {
    if (this._fetchController) this._fetchController.abort()
    this._fetchController = new AbortController()

    const url = this.buildDataUrl(sendDateParams)
    fetch(url, { headers: { "Accept": "application/json" }, signal: this._fetchController.signal })
      .then(r => {
        if (!r.ok) throw new Error(`HTTP ${r.status}`)
        return r.json()
      })
      .then(data => {
        const projects = data.projects || []
        const tasks = []
        projects.forEach(p => {
          ;(p.phases || []).forEach(ph => { (ph.tasks || []).forEach(t => tasks.push(t)) })
          ;(p.tasks || []).forEach(t => tasks.push(t))
        })
        if (!sendDateParams) {
          if (tasks.length > 0) {
            const starts = tasks.map(t => new Date(t.planned_start_date).getTime())
            this.anchorDate = new Date(Math.min(...starts))
          } else {
            const today = new Date()
            today.setHours(0, 0, 0, 0)
            this.anchorDate = today
          }
          this.fetchAndRender(true)
          return
        }
        this.chartData = data
        this.render()
      })
      .catch(err => {
        if (err.name === "AbortError") return
        if (this.hasChartTarget) {
          this.chartTarget.textContent = `Failed to load Gantt data: ${err.message}`
        }
      })
  }

  periodSliderChanged() {
    if (!this.hasPeriodSliderTarget) return
    const sliderValue = parseInt(this.periodSliderTarget.value, 10)
    if (Number.isNaN(sliderValue) || sliderValue < 0 || sliderValue > 5) return
    const periodDays = PERIOD_DAYS[sliderValue]
    if (!periodDays) return
    this.periodValue = periodDays
    this.updatePeriodLabel()
    this.persistPeriod(this.periodValue)
    this.fetchAndRender(true)
  }

  projectChanged() {
    this.updateProjectDropdownSummary()
    this.anchorDate = null
    this.fetchAndRender(false)
  }

  toggleProjectDropdown(event) {
    event.stopPropagation()
    if (!this.hasProjectDropdownPanelTarget) return
    const panel = this.projectDropdownPanelTarget
    panel.classList.toggle("hidden")
    const isOpen = !panel.classList.contains("hidden")
    panel.setAttribute("aria-hidden", !isOpen)
    if (this.hasProjectDropdownTriggerTarget) {
      this.projectDropdownTriggerTarget.setAttribute("aria-expanded", isOpen)
    }
    if (isOpen) this.updateProjectDropdownSummary()
  }

  closeProjectDropdown(event) {
    if (!this.hasProjectDropdownPanelTarget || this.projectDropdownPanelTarget.classList.contains("hidden")) return
    if (this.hasProjectDropdownWrapperTarget && this.projectDropdownWrapperTarget.contains(event.target)) return
    this.projectDropdownPanelTarget.classList.add("hidden")
    this.projectDropdownPanelTarget.setAttribute("aria-hidden", "true")
    if (this.hasProjectDropdownTriggerTarget) {
      this.projectDropdownTriggerTarget.setAttribute("aria-expanded", "false")
    }
  }

  updateProjectDropdownSummary() {
    if (!this.hasProjectDropdownSummaryTarget) return
    const n = this.hasProjectCheckboxTarget
      ? this.projectCheckboxTargets.filter(cb => cb.checked).length
      : 0
    const allLabel = this.allProjectsValue || "All projects"
    const selectedLabel = this.projectsSelectedValue || "%{count} projects"
    this.projectDropdownSummaryTarget.textContent = n === 0 ? allLabel : selectedLabel.replace("%{count}", String(n))
  }

  selectAllProjects() {
    if (this.hasProjectCheckboxTarget) {
      this.projectCheckboxTargets.forEach(cb => { cb.checked = true })
    }
    this.updateProjectDropdownSummary()
    this.anchorDate = null
    this.fetchAndRender(false)
  }

  clearProjects() {
    if (this.hasProjectCheckboxTarget) {
      this.projectCheckboxTargets.forEach(cb => { cb.checked = false })
    }
    this.updateProjectDropdownSummary()
    this.anchorDate = null
    this.fetchAndRender(false)
  }

  persistPeriod(periodDays) {
    fetch("/user_settings", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": csrfToken()
      },
      body: `user_setting[last_gantt_zoom]=${periodDays}`
    }).catch(() => {})
  }

  render() {
    if (!this.hasChartTarget) return
    try {
      const container = this.chartTarget
      container.innerHTML = ""

      const projects = this.chartData.projects || []
      if (projects.length === 0) {
        container.innerHTML = '<p class="text-gray-500 p-4">No tasks to display.</p>'
        return
      }

      const rows = []
      projects.forEach(p => {
        const projStart = new Date(p.planned_start_date)
        const projEnd = new Date(p.planned_end_date)
        projEnd.setDate(projEnd.getDate() + 1)
        rows.push({ type: "project", id: p.id, name: p.name, status: p.status, start: projStart, end: projEnd, rawEnd: new Date(p.planned_end_date) })

        const pushTask = (t, phaseRow = null) => {
          const endDate = new Date(t.planned_end_date)
          endDate.setDate(endDate.getDate() + 1)
          rows.push({
            type: "task",
            id: t.id,
            projectId: p.id,
            phaseId: t.phase_id || null,
            name: t.name,
            status: t.status,
            start: new Date(t.planned_start_date),
            end: endDate,
            projectStart: projStart,
            projectEnd: projEnd,
            rawEnd: new Date(t.planned_end_date)
          })
        }

        ;(p.phases || []).forEach(ph => {
          const phEnd = new Date(ph.planned_end_date)
          phEnd.setDate(phEnd.getDate() + 1)
          rows.push({
            type: "phase", id: ph.id, projectId: p.id, name: ph.name, status: ph.status,
            start: new Date(ph.planned_start_date), end: phEnd, rawEnd: new Date(ph.planned_end_date)
          })
          ;(ph.tasks || []).forEach(t => pushTask(t, ph))
        })
        ;(p.tasks || []).forEach(t => pushTask(t))
      })

      const taskRows = rows.filter(r => r.type === "task")
      if (taskRows.length === 0) {
        container.innerHTML = '<p class="text-gray-500 p-4">No tasks to display.</p>'
        return
      }

      const periodDays = Math.max(7, Math.min(365, this.periodValue || 30))
      const xMin = this.anchorDate ? new Date(this.anchorDate.getTime()) : new Date()
      const xMax = new Date(xMin.getTime() + periodDays * MS_PER_DAY)
      const totalDays = (xMax - xMin) / MS_PER_DAY
      const pixelsPerDay = pixelsPerDayFromPeriodDays(periodDays)
      let width = this.margin.left + this.margin.right + totalDays * pixelsPerDay
      const minWidth = container.clientWidth || width
      width = Math.max(width, minWidth)
      const height = this.margin.top + rows.length * this.rowHeight + this.margin.bottom

      const svg = d3.select(container)
        .append("svg")
        .attr("width", width)
        .attr("height", height)
        .attr("role", "img")
        .attr("aria-label", "Gantt chart")

      const xScale = d3.scaleTime()
        .domain([xMin, xMax])
        .range([this.margin.left, width - this.margin.right])

      let tickInterval, tickFormat
      if (periodDays <= 7) {
        tickInterval = d3.timeDay.every(1)
        tickFormat = d3.timeFormat("%d/%m")
      } else if (periodDays <= 30) {
        tickInterval = d3.timeWeek.every(1)
        tickFormat = d3.timeFormat("%d/%m")
      } else {
        tickInterval = d3.timeMonth.every(1)
        tickFormat = d3.timeFormat("%b %Y")
      }

      const xAxis = d3.axisTop(xScale)
        .ticks(tickInterval)
        .tickFormat(tickFormat)

      svg.append("g")
        .attr("transform", `translate(0,${this.margin.top})`)
        .call(xAxis)
        .selectAll("text")
        .attr("class", "text-xs fill-gray-500")

      svg.append("g")
        .attr("class", "grid")
        .selectAll("line")
        .data(xScale.ticks(tickInterval))
        .enter()
        .append("line")
        .attr("x1", d => xScale(d))
        .attr("x2", d => xScale(d))
        .attr("y1", this.margin.top)
        .attr("y2", height - this.margin.bottom)
        .attr("stroke", "#e5e7eb")
        .attr("stroke-dasharray", "2,2")

      const today = new Date()
      if (today >= xMin && today <= xMax) {
        svg.append("line")
          .attr("x1", xScale(today))
          .attr("x2", xScale(today))
          .attr("y1", this.margin.top)
          .attr("y2", height - this.margin.bottom)
          .attr("stroke", "#ef4444")
          .attr("stroke-width", 2)
          .attr("stroke-dasharray", "4,2")
      }

      rows.forEach((row, i) => {
        const y = this.margin.top + i * this.rowHeight
        let fill = "#ffffff"
        if (row.type === "project") fill = "#f3f4f6"
        else if (row.type === "phase") fill = "#e5e7eb"
        else fill = (i % 2 === 0 ? "#ffffff" : "#fafafa")
        svg.append("rect")
          .attr("x", 0)
          .attr("y", y)
          .attr("width", width)
          .attr("height", this.rowHeight)
          .attr("fill", fill)
      })

      const labelWidth = this.margin.left - 20
      rows.forEach((row, i) => {
        const y = this.margin.top + i * this.rowHeight
        let x = 8
        let labelClass = "gantt-label gantt-label-task text-xs text-gray-600"
        if (row.type === "project") {
          x = 6
          labelClass = "gantt-label gantt-label-project text-xs font-semibold text-gray-800"
        } else if (row.type === "phase") {
          x = 14
          labelClass = "gantt-label gantt-label-phase text-xs font-medium text-gray-700"
        }
        const fo = svg.append("foreignObject")
          .attr("x", x)
          .attr("y", y)
          .attr("width", labelWidth - x)
          .attr("height", this.rowHeight)
        fo.append("xhtml:div")
          .attr("class", labelClass)
          .style("word-wrap", "break-word")
          .style("overflow-wrap", "break-word")
          .style("white-space", "normal")
          .style("line-height", "1.25")
          .style("padding", "0 4px")
          .style("display", "flex")
          .style("align-items", "center")
          .style("min-height", `${this.rowHeight}px`)
          .text(row.name || "")

        if (row.type === "project") {
          fo
            .attr("cursor", "pointer")
            .style("text-decoration", "underline")
            .on("click", () => { window.location.href = `/projects/${row.id}` })
        } else if (row.type === "phase") {
          fo
            .attr("cursor", "pointer")
            .style("text-decoration", "underline")
            .on("click", () => { window.location.href = `/projects/${row.projectId}/phases/${row.id}` })
        } else if (row.type === "task") {
          fo
            .attr("cursor", "pointer")
            .style("text-decoration", "underline")
            .on("click", () => { window.location.href = `/projects/${row.projectId}/tasks/${row.id}` })
        }
      })

      svg.append("line")
        .attr("x1", this.margin.left - 10)
        .attr("x2", this.margin.left - 10)
        .attr("y1", this.margin.top)
        .attr("y2", height - this.margin.bottom)
        .attr("stroke", "#d1d5db")

      const statusColors = {
        planned: "#9ca3af",
        in_progress: "#fbbf24",
        done: "#34d399",
        cancelled: "#f87171",
        active: "#60a5fa",
        completed: "#34d399",
        on_hold: "#fb923c"
      }

      const groupRowsWithIndex = rows.map((r, i) => ({ ...r, index: i })).filter(r => (r.type === "project" || r.type === "phase") && r.start && r.end)
      const groupColors = { project: "#818cf8", phase: "#a78bfa" }

      svg.selectAll(".group-bar")
        .data(groupRowsWithIndex)
        .enter()
        .append("rect")
        .attr("class", "group-bar")
        .attr("x", d => xScale(d.start))
        .attr("y", d => this.margin.top + d.index * this.rowHeight + (this.rowHeight - this.barHeight) / 2)
        .attr("width", d => Math.max(xScale(d.end) - xScale(d.start), 4))
        .attr("height", this.barHeight)
        .attr("rx", 4)
        .attr("fill", d => groupColors[d.type])
        .attr("cursor", "pointer")
        .attr("opacity", 0.85)
        .on("mouseover", (event, d) => this.showTooltip(event, d))
        .on("mouseout", () => this.hideTooltip())
        .on("click", (event, d) => {
          if (d.type === "project") window.location.href = `/projects/${d.id}`
          else window.location.href = `/projects/${d.projectId}/phases/${d.id}`
        })

      const taskRowsWithIndex = rows.map((r, i) => ({ ...r, index: i })).filter(r => r.type === "task")

      const bars = svg.selectAll(".task-bar")
        .data(taskRowsWithIndex)
        .enter()
        .append("rect")
        .attr("class", "task-bar")
        .attr("x", d => xScale(d.start))
        .attr("y", d => this.margin.top + d.index * this.rowHeight + (this.rowHeight - this.barHeight) / 2)
        .attr("width", d => Math.max(xScale(d.end) - xScale(d.start), 4))
        .attr("height", this.barHeight)
        .attr("rx", 4)
        .attr("fill", d => statusColors[d.status] || "#9ca3af")
        .attr("cursor", this.canEditValue ? "grab" : "pointer")
        .attr("opacity", 0.85)
        .on("mouseover", (event, d) => this.showTooltip(event, d))
        .on("mouseout", () => this.hideTooltip())
        .on("click", (event, d) => {
          window.location.href = `/projects/${d.projectId}/tasks/${d.id}`
        })

      if (this.canEditValue) {
        const self = this
        const drag = d3.drag()
          .on("start", function(event, d) {
            d._origX = xScale(d.start)
            d._barWidth = xScale(d.end) - xScale(d.start)
            d3.select(this).attr("opacity", 1).attr("cursor", "grabbing")
          })
          .on("drag", function(event, d) {
            const newX = Math.max(self.margin.left, event.x)
            d3.select(this).attr("x", newX)
          })
          .on("end", function(event, d) {
            d3.select(this).attr("opacity", 0.85).attr("cursor", "grab")
            const newStartDate = xScale.invert(parseFloat(d3.select(this).attr("x")))
            const duration = d.end - d.start
            const newEndDate = new Date(newStartDate.getTime() + duration)

            if (newStartDate < d.projectStart || newEndDate > d.projectEnd) {
              const extendMsg = `Task dates fall outside the project range (${formatDate(d.projectStart)} - ${formatDate(d.projectEnd)}). Adjust project dates first.`
              showToast(extendMsg)
              d3.select(this).attr("x", xScale(d.start))
              return
            }

            self.updateTaskDates(d.id, d.projectId, newStartDate, newEndDate, d)
          })

        bars.call(drag)
      }
    } catch (error) {
      if (this.hasChartTarget) {
        this.chartTarget.textContent = `Error rendering chart: ${error.message}`
      }
    }
  }

  showTooltip(event, d) {
    if (!this.hasTooltipTarget) return
    const tip = this.tooltipTarget
    const displayEnd = d.rawEnd || d.end
    tip.innerHTML = `
      <div class="font-medium">${escapeHtml(d.name)}</div>
      <div class="text-xs text-gray-500 mt-1">
        ${escapeHtml(formatDate(d.start))} - ${escapeHtml(formatDate(displayEnd))}
      </div>
      <div class="text-xs mt-1">Status: ${escapeHtml((d.status || "unknown").replace("_", " "))}</div>
    `
    tip.style.display = "block"
    tip.style.left = `${event.pageX + 12}px`
    tip.style.top = `${event.pageY - 12}px`
  }

  hideTooltip() {
    if (!this.hasTooltipTarget) return
    this.tooltipTarget.style.display = "none"
  }

  updateTaskDates(taskId, projectId, newStart, newEnd, d) {
    const startStr = newStart.toISOString().split("T")[0]
    const endStr = newEnd.toISOString().split("T")[0]

    fetch(this.updateUrlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken(),
        "Accept": "application/json"
      },
      body: JSON.stringify({
        task_id: taskId,
        planned_start_date: startStr,
        planned_end_date: endStr
      })
    })
      .then(r => r.json())
      .then(result => {
        if (result.success) {
          d.start = newStart
          d.end = newEnd
        } else {
          showToast(result.error || "Failed to update task dates.")
          this.fetchAndRender(false)
        }
      })
      .catch(() => {
        showToast("Network error. Changes reverted.")
        this.fetchAndRender(false)
      })
  }
}
