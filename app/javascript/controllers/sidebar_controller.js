import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay"]

  toggle() {
    const isOpen = !this.sidebarTarget.classList.contains("-translate-x-full")
    if (isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.sidebarTarget.classList.remove("-translate-x-full")
    this.overlayTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden", "md:overflow-auto")
  }

  close() {
    this.sidebarTarget.classList.add("-translate-x-full")
    this.overlayTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden", "md:overflow-auto")
  }

  // Close sidebar when navigating via Turbo on mobile
  navigate() {
    if (window.innerWidth < 768) {
      this.close()
    }
  }

  disconnect() {
    document.body.classList.remove("overflow-hidden", "md:overflow-auto")
  }
}
