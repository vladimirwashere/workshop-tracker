import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit(event) {
    // Submit form when select/input changes
    const form = this.element.closest("form")
    if (form) {
      form.requestSubmit()
    }
  }
}
