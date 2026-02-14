import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "from", "to", "thisWeekButton", "thisMonthButton", "thisYearButton"]

  connect() {
    this.updateActiveButton()
  }

  submitForm() {
    if (this.hasFormTarget) {
      this.formTarget.requestSubmit()
    }
  }

  setThisWeek(event) {
    event.preventDefault()
    if (!this.hasFromTarget || !this.hasToTarget) return
    const today = new Date()
    const day = today.getDay()
    const diff = today.getDate() - day + (day === 0 ? -6 : 1)
    const monday = new Date(today)
    monday.setDate(diff)
    const sunday = new Date(monday)
    sunday.setDate(monday.getDate() + 6)
    this.fromTarget.value = this.formatDate(monday)
    this.toTarget.value = this.formatDate(sunday)
    this.setActiveButton("thisWeek")
    this.submitForm()
  }

  setThisMonth(event) {
    event.preventDefault()
    if (!this.hasFromTarget || !this.hasToTarget) return
    const today = new Date()
    const first = new Date(today.getFullYear(), today.getMonth(), 1)
    const last = new Date(today.getFullYear(), today.getMonth() + 1, 0)
    this.fromTarget.value = this.formatDate(first)
    this.toTarget.value = this.formatDate(last)
    this.setActiveButton("thisMonth")
    this.submitForm()
  }

  setThisYear(event) {
    event.preventDefault()
    if (!this.hasFromTarget || !this.hasToTarget) return
    const today = new Date()
    const first = new Date(today.getFullYear(), 0, 1)
    const last = new Date(today.getFullYear(), 11, 31)
    this.fromTarget.value = this.formatDate(first)
    this.toTarget.value = this.formatDate(last)
    this.setActiveButton("thisYear")
    this.submitForm()
  }

  updateActiveButton() {
    if (!this.hasFromTarget || !this.hasToTarget) return

    const fromDate = new Date(this.fromTarget.value)
    const toDate = new Date(this.toTarget.value)

    if (isNaN(fromDate.getTime()) || isNaN(toDate.getTime())) return

    const activePeriod = this.detectActivePeriod(fromDate, toDate)
    this.setActiveButton(activePeriod)
  }

  detectActivePeriod(fromDate, toDate) {
    const today = new Date()
    
    const day = today.getDay()
    const diff = today.getDate() - day + (day === 0 ? -6 : 1)
    const monday = new Date(today)
    monday.setDate(diff)
    const sunday = new Date(monday)
    sunday.setDate(monday.getDate() + 6)
    if (this.datesMatch(fromDate, monday) && this.datesMatch(toDate, sunday)) {
      return "thisWeek"
    }

    const monthStart = new Date(today.getFullYear(), today.getMonth(), 1)
    const monthEnd = new Date(today.getFullYear(), today.getMonth() + 1, 0)
    if (this.datesMatch(fromDate, monthStart) && this.datesMatch(toDate, monthEnd)) {
      return "thisMonth"
    }

    const yearStart = new Date(today.getFullYear(), 0, 1)
    const yearEnd = new Date(today.getFullYear(), 11, 31)
    if (this.datesMatch(fromDate, yearStart) && this.datesMatch(toDate, yearEnd)) {
      return "thisYear"
    }

    return null
  }

  datesMatch(date1, date2) {
    return date1.getFullYear() === date2.getFullYear() &&
           date1.getMonth() === date2.getMonth() &&
           date1.getDate() === date2.getDate()
  }

  setActiveButton(activePeriod) {
    const buttons = {
      thisWeek: this.hasThisWeekButtonTarget ? this.thisWeekButtonTarget : null,
      thisMonth: this.hasThisMonthButtonTarget ? this.thisMonthButtonTarget : null,
      thisYear: this.hasThisYearButtonTarget ? this.thisYearButtonTarget : null
    }

    Object.entries(buttons).forEach(([key, button]) => {
      if (button) {
        const isActive = activePeriod === key
        button.classList.toggle("bg-indigo-100", isActive)
        button.classList.toggle("border-indigo-500", isActive)
        button.classList.toggle("text-indigo-700", isActive)
        button.classList.toggle("font-medium", isActive)
        button.classList.toggle("border-gray-300", !isActive)
        button.classList.toggle("text-gray-700", !isActive)
      }
    })
  }

  formatDate(date) {
    return date.toISOString().split("T")[0]
  }
}
