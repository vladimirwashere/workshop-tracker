import { Controller } from "@hotwired/stimulus"
import { showToast } from "helpers/toast"
import { csrfToken } from "helpers/csrf_token"

export default class extends Controller {
  static targets = ["button"]
  static values = { current: String }

  toggle() {
    const currentCurrency = this.getCurrentCurrency()
    const newCurrency = currentCurrency === "RON" ? "GBP" : "RON"

    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = true
    }

    const formData = new FormData()
    formData.append("user_setting[default_currency_display]", newCurrency)

    fetch("/user_settings", {
      method: "PATCH",
      body: formData,
      headers: {
        "X-CSRF-Token": csrfToken(),
        "Accept": "application/json"
      }
    })
      .then(response => {
        if (response.ok) {
          this.currentValue = newCurrency
          window.location.reload()
        } else {
          throw new Error("Failed to update currency")
        }
      })
      .catch(() => {
        if (this.hasButtonTarget) {
          this.buttonTarget.disabled = false
        }
        showToast("Failed to update currency. Please try again.")
      })
  }

  getCurrentCurrency() {
    return this.currentValue || "RON"
  }
}
