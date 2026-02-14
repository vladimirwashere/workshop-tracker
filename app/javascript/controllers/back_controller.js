import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { fallback: String }

  go(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const fallbackUrl = this.fallbackValue || "/"
    
    // Navigate to fallback URL (tree-based navigation)
    // Turbo Drive will handle this automatically if it's a same-origin navigation
    window.location.href = fallbackUrl
  }
}
