import { Controller } from "@hotwired/stimulus"

// Generic modal controller using Turbo Frames.
// Opens a modal dialog, loads content via Turbo Frame, and closes on Escape/X button.
export default class extends Controller {
  static targets = ["dialog"]

  connect() {
    this._onFrameLoad = this._handleFrameLoad.bind(this)
    const frame = this.dialogTarget.querySelector("turbo-frame")
    if (frame) frame.addEventListener("turbo:frame-load", this._onFrameLoad)
  }

  disconnect() {
    const frame = this.dialogTarget.querySelector("turbo-frame")
    if (frame) frame.removeEventListener("turbo:frame-load", this._onFrameLoad)
  }

  open(event) {
    event.preventDefault()
    const url = event.currentTarget.getAttribute("href") || event.params.url
    if (!url) return

    const frame = this.dialogTarget.querySelector("turbo-frame")
    if (frame) {
      frame.src = url
      frame.reload()
    }

    this.dialogTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  close() {
    this.dialogTarget.classList.add("hidden")
    document.body.style.overflow = ""

    const frame = this.dialogTarget.querySelector("turbo-frame")
    if (frame) {
      frame.src = ""
      frame.innerHTML = ""
    }
  }

  keydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  // Auto-close modal and refresh page when turbo frame loads empty content (successful redirect)
  _handleFrameLoad() {
    const frame = this.dialogTarget.querySelector("turbo-frame")
    if (frame && frame.innerHTML.trim() === "") {
      this.close()
      Turbo.visit(window.location.href, { action: "replace" })
    }
  }
}
