import { Controller } from "@hotwired/stimulus"
import * as d3 from "d3"
import { formatDate } from "helpers/format_date"
import { escapeHtml } from "helpers/escape_html"

export default class extends Controller {
  static targets = ["chart", "tooltip"]
  static values = {
    dataUrl: String,
    showCosts: { type: Boolean, default: false }
  }

  connect() {
    this.margin = { top: 40, right: 30, bottom: 30, left: 180 }
    this.rowHeight = 36
    this.barHeight = 14
    this._resizeHandler = () => this.render()
    window.addEventListener("resize", this._resizeHandler)
    this.fetchAndRender()
  }

  disconnect() {
    window.removeEventListener("resize", this._resizeHandler)
    this.chartTarget.innerHTML = ""
  }

  fetchAndRender() {
    fetch(this.dataUrlValue, { headers: { "Accept": "application/json" } })
      .then(r => {
        if (!r.ok) throw new Error(`HTTP ${r.status}: ${r.statusText}`)
        return r.json()
      })
      .then(data => {
        this.timelineData = data
        this.render()
      })
      .catch(err => {
        this.chartTarget.textContent = `Failed to load timeline data: ${err.message}`
      })
  }

  render() {
    const container = this.chartTarget
    container.innerHTML = ""

    const logs = this.timelineData.logs || []

    if (logs.length === 0) {
      container.innerHTML = '<p class="text-gray-500 p-4">No logs for this worker.</p>'
      return
    }

    const projectIds = [...new Set([
      ...logs.map(l => l.project_id)
    ])]
    const colorScale = d3.scaleOrdinal(d3.schemeTableau10).domain(projectIds)

    const projectMap = {}
    const addToProject = (pid, pname) => {
      if (!projectMap[pid]) projectMap[pid] = { id: pid, name: pname }
    }
    logs.forEach(l => addToProject(l.project_id, l.project_name))

    const rows = Object.values(projectMap)

    const allDates = [
      ...logs.map(l => new Date(l.date))
    ]

    if (allDates.length === 0) {
      container.innerHTML = '<p class="text-gray-500 p-4">No data to display.</p>'
      return
    }

    const minDate = d3.min(allDates)
    const maxDate = d3.max(allDates)
    const pad = 3 * 24 * 60 * 60 * 1000
    const xMin = new Date(minDate.getTime() - pad)
    const xMax = new Date(maxDate.getTime() + pad)

    const width = Math.max(container.clientWidth, 700)
    const height = this.margin.top + rows.length * this.rowHeight + this.margin.bottom

    const svg = d3.select(container)
      .append("svg")
      .attr("width", width)
      .attr("height", height)
      .attr("role", "img")
      .attr("aria-label", "Worker timeline")

    const xScale = d3.scaleTime()
      .domain([xMin, xMax])
      .range([this.margin.left, width - this.margin.right])

    const xAxis = d3.axisTop(xScale).ticks(d3.timeWeek.every(1)).tickFormat(d3.timeFormat("%d/%m"))
    svg.append("g")
      .attr("transform", `translate(0,${this.margin.top})`)
      .call(xAxis)
      .selectAll("text")
      .attr("class", "text-xs fill-gray-500")

    svg.append("g")
      .selectAll("line")
      .data(xScale.ticks(d3.timeWeek.every(1)))
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
        .attr("x1", xScale(today)).attr("x2", xScale(today))
        .attr("y1", this.margin.top).attr("y2", height - this.margin.bottom)
        .attr("stroke", "#ef4444").attr("stroke-width", 2)        .attr("stroke-dasharray", "4,2")
    }

    rows.forEach((row, i) => {
      const y = this.margin.top + i * this.rowHeight

      svg.append("rect")
        .attr("x", 0).attr("y", y).attr("width", width).attr("height", this.rowHeight)
        .attr("fill", i % 2 === 0 ? "#ffffff" : "#fafafa")

      svg.append("text")
        .attr("x", 10).attr("y", y + this.rowHeight / 2).attr("dy", "0.35em")
        .attr("class", "text-xs fill-gray-700 font-medium")
        .text(row.name.length > 22 ? row.name.slice(0, 20) + "..." : row.name)

      // Actual hours (bars per day)
      const projectLogs = logs.filter(l => l.project_id === row.id)
      projectLogs.forEach(l => {
        const logDate = new Date(l.date)
        const barHeight = Math.min(Math.max(l.hours * 2, 4), 16)
        const barY = y + this.rowHeight / 2 - barHeight / 2 + 4
        
        const logBar = svg.append("rect")
          .attr("x", xScale(logDate) - 2)
          .attr("y", barY)
          .attr("width", 4)
          .attr("height", barHeight)
          .attr("rx", 2)
          .attr("fill", colorScale(row.id))
          .attr("opacity", 0.85)
          .attr("stroke", colorScale(row.id))
          .attr("stroke-width", 1)
          .attr("cursor", "pointer")
          .attr("class", "log-bar")
          .on("mouseover", (event, d) => {
            this.showLogTooltip(event, l, row.name)
            d3.select(event.currentTarget).attr("opacity", 1).attr("stroke-width", 2)
          })
          .on("mouseout", (event, d) => {
            this.hideTooltip()
            d3.select(event.currentTarget).attr("opacity", 0.85).attr("stroke-width", 1)
          })
          .on("click", () => {
            window.location.href = `/projects/${l.project_id}/tasks/${l.task_id}`
          })
      })
    })

    // Separator
    svg.append("line")
      .attr("x1", this.margin.left - 10).attr("x2", this.margin.left - 10)
      .attr("y1", this.margin.top).attr("y2", height - this.margin.bottom)
      .attr("stroke", "#d1d5db")
  }

  showLogTooltip(event, log, projectName) {
    if (!this.hasTooltipTarget) return
    const tip = this.tooltipTarget
    // Get coordinates from event (D3 v7+ uses event.pageX/pageY directly)
    const x = event.pageX ?? event.sourceEvent?.pageX ?? 0
    const y = event.pageY ?? event.sourceEvent?.pageY ?? 0
    
    tip.innerHTML = `
      <div class="font-medium">${escapeHtml(log.task_name)}</div>
      <div class="text-xs text-gray-500 mt-1">${escapeHtml(projectName)}</div>
      <div class="text-xs text-gray-500 mt-1">${escapeHtml(formatDate(log.date))}</div>
      ${this.showCostsValue && log.cost ? `<div class="text-xs mt-1">Cost: ${escapeHtml(log.cost)} RON</div>` : ""}
    `
    tip.style.display = "block"
    tip.style.left = `${x + 12}px`
    tip.style.top = `${y - 12}px`
  }

  hideTooltip() {
    if (!this.hasTooltipTarget) return
    this.tooltipTarget.style.display = "none"
  }

}
