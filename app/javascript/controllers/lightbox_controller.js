import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "image", "prevBtn", "nextBtn"]

  connect() {
    this.currentIndex = 0
    this.images = []
    this._keyHandler = (e) => this.handleKeydown(e)
  }

  disconnect() {
    document.removeEventListener("keydown", this._keyHandler)
    document.body.style.overflow = ""
  }

  handleKeydown(event) {
    switch (event.key) {
      case "Escape":
        this.close(event)
        break
      case "ArrowLeft":
        this.prev(event)
        break
      case "ArrowRight":
        this.next(event)
        break
    }
  }

  open(event) {
    event.preventDefault()
    event.stopPropagation()

    // Collect all image sources from lightbox-openable elements
    this.images = Array.from(
      this.element.querySelectorAll("[data-action*='lightbox#open']")
    ).map(el => ({
      src: el.dataset.lightboxSrcParam,
      alt: el.dataset.lightboxAltParam || ""
    }))

    const index = parseInt(event.params.index, 10) || 0
    this.currentIndex = index

    this.showImage()
    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    document.addEventListener("keydown", this._keyHandler)
  }

  close(event) {
    // Only close if clicking the backdrop or close button, not the image itself
    if (event.type === "click" && event.target === this.imageTarget) return

    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""
    document.removeEventListener("keydown", this._keyHandler)
  }

  prev(event) {
    event.stopPropagation()
    if (this.images.length === 0) return
    this.currentIndex = (this.currentIndex - 1 + this.images.length) % this.images.length
    this.showImage()
  }

  next(event) {
    event.stopPropagation()
    if (this.images.length === 0) return
    this.currentIndex = (this.currentIndex + 1) % this.images.length
    this.showImage()
  }

  showImage() {
    if (this.images.length === 0) return

    const image = this.images[this.currentIndex]
    this.imageTarget.src = image.src
    this.imageTarget.alt = image.alt

    // Show/hide nav buttons based on image count
    const hasMultiple = this.images.length > 1
    if (this.hasPrevBtnTarget) {
      this.prevBtnTarget.classList.toggle("hidden", !hasMultiple)
    }
    if (this.hasNextBtnTarget) {
      this.nextBtnTarget.classList.toggle("hidden", !hasMultiple)
    }
  }
}
