import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "dropZone", "fileInput", "previewArea", "previewList", "fileCount", "submitButton", "errorToast", "errorMessage"]
  static values = {
    maxSize: { type: Number, default: 26214400 },
    allowedTypes: { type: String, default: "" }
  }

  connect() {
    this.selectedFiles = []
    this.allowedTypesSet = new Set(this.allowedTypesValue.split(",").filter(Boolean))
  }

  disconnect() {
    clearTimeout(this._errorTimeout)
  }

  triggerFileInput(event) {
    // Don't trigger if clicking the submit button or clear button
    if (event.target.closest("button") || event.target.closest("[type='submit']")) return
    this.fileInputTarget.click()
  }

  dragOver(event) {
    event.preventDefault()
    event.stopPropagation()
  }

  dragEnter(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropZoneTarget.classList.add("border-blue-500", "bg-blue-50")
    this.dropZoneTarget.classList.remove("border-slate-300")
  }

  dragLeave(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropZoneTarget.classList.remove("border-blue-500", "bg-blue-50")
    this.dropZoneTarget.classList.add("border-slate-300")
  }

  drop(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropZoneTarget.classList.remove("border-blue-500", "bg-blue-50")
    this.dropZoneTarget.classList.add("border-slate-300")

    const files = Array.from(event.dataTransfer.files)
    this.addFiles(files)
  }

  filesSelected(event) {
    const files = Array.from(event.target.files)
    this.addFiles(files)
    // Reset input so the same file can be re-selected
    event.target.value = ""
  }

  addFiles(files) {
    const errors = []

    files.forEach(file => {
      if (file.size > this.maxSizeValue) {
        errors.push(`${file.name}: exceeds 25 MB limit`)
        return
      }

      if (this.allowedTypesSet.size > 0 && !this.allowedTypesSet.has(file.type)) {
        errors.push(`${file.name}: unsupported file type`)
        return
      }

      // Avoid duplicates by name + size
      const isDuplicate = this.selectedFiles.some(
        f => f.name === file.name && f.size === file.size
      )
      if (!isDuplicate) {
        this.selectedFiles.push(file)
      }
    })

    if (errors.length > 0) {
      this.showError(errors.join("; "))
    }

    this.renderPreviews()
  }

  clearFiles() {
    this.selectedFiles = []
    this.renderPreviews()
  }

  removeFile(event) {
    const index = parseInt(event.currentTarget.dataset.index, 10)
    this.selectedFiles.splice(index, 1)
    this.renderPreviews()
  }

  renderPreviews() {
    if (this.selectedFiles.length === 0) {
      this.previewAreaTarget.classList.add("hidden")
      this.previewListTarget.innerHTML = ""
      this.syncFormFiles()
      return
    }

    this.previewAreaTarget.classList.remove("hidden")
    this.fileCountTarget.textContent = `${this.selectedFiles.length} file${this.selectedFiles.length === 1 ? "" : "s"} selected`

    this.previewListTarget.innerHTML = ""

    this.selectedFiles.forEach((file, index) => {
      const card = document.createElement("div")
      card.className = "relative bg-slate-50 border border-slate-200 rounded-lg p-2 flex flex-col items-center"

      const isImage = file.type.startsWith("image/") && ["image/jpeg", "image/png", "image/gif", "image/webp"].includes(file.type)

      if (isImage) {
        const img = document.createElement("img")
        img.className = "w-full h-20 object-cover rounded mb-1"
        img.alt = file.name
        const reader = new FileReader()
        reader.onload = (e) => { img.src = e.target.result }
        reader.readAsDataURL(file)
        card.appendChild(img)
      } else {
        const icon = document.createElement("div")
        icon.className = "w-full h-20 flex items-center justify-center text-slate-400 mb-1"
        const ext = file.name.split(".").pop()?.toUpperCase() || "FILE"
        icon.innerHTML = `<span class="text-xs font-bold text-slate-500 bg-slate-200 px-2 py-1 rounded">${ext}</span>`
        card.appendChild(icon)
      }

      const name = document.createElement("p")
      name.className = "text-xs text-slate-600 break-words w-full text-center"
      name.title = file.name
      name.textContent = file.name
      card.appendChild(name)

      const size = document.createElement("p")
      size.className = "text-xs text-slate-400"
      size.textContent = this.formatFileSize(file.size)
      card.appendChild(size)

      // Remove button
      const removeBtn = document.createElement("button")
      removeBtn.type = "button"
      removeBtn.className = "absolute -top-2 -right-2 w-5 h-5 bg-red-500 text-white rounded-full flex items-center justify-center text-xs hover:bg-red-600 transition-colors"
      removeBtn.innerHTML = "&times;"
      removeBtn.dataset.index = index
      removeBtn.dataset.action = "click->attachment-upload#removeFile"
      card.appendChild(removeBtn)

      this.previewListTarget.appendChild(card)
    })

    this.syncFormFiles()
  }

  syncFormFiles() {
    // Create a new DataTransfer to set files on the input
    const dt = new DataTransfer()
    this.selectedFiles.forEach(file => dt.items.add(file))
    this.fileInputTarget.files = dt.files
  }

  showError(message) {
    this.errorMessageTarget.textContent = message
    this.errorToastTarget.classList.remove("hidden")
    clearTimeout(this._errorTimeout)
    this._errorTimeout = setTimeout(() => {
      this.errorToastTarget.classList.add("hidden")
    }, 5000)
  }

  formatFileSize(bytes) {
    if (bytes === 0) return "0 B"
    const k = 1024
    const sizes = ["B", "KB", "MB", "GB"]
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i]
  }
}
