import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["value"]

  copy() {
    const text = this.valueTarget.textContent.trim()
    navigator.clipboard.writeText(text).then(() => {
      this.element.querySelector("[data-clipboard-feedback]")?.classList?.remove("hidden")
      setTimeout(() => {
        this.element.querySelector("[data-clipboard-feedback]")?.classList?.add("hidden")
      }, 2000)
    })
  }
}
