import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "displayField", "formField", "changePasswordSection",
    "confirmPasswordSection", "editButton", "saveButton",
    "emailField", "newPassword", "confirmPassword", "currentPassword"
  ]
  static values = {
    editing: { type: Boolean, default: false },
    originalEmail: String
  }

  connect() {
    if (this.editingValue) {
      this.showEditMode()
    } else {
      this.showViewMode()
    }
  }

  edit(event) {
    event.preventDefault()
    this.showEditMode()
  }

  checkSensitive() {
    const emailChanged = this.hasEmailFieldTarget &&
      this.emailFieldTarget.value !== this.originalEmailValue
    const passwordFilled = this.hasNewPasswordTarget &&
      this.newPasswordTarget.value.length > 0

    if (emailChanged || passwordFilled) {
      this.confirmPasswordSectionTarget.classList.remove("hidden")
      this.currentPasswordTarget.required = true
    } else {
      this.confirmPasswordSectionTarget.classList.add("hidden")
      this.currentPasswordTarget.required = false
      this.currentPasswordTarget.value = ""
    }
  }

  showEditMode() {
    this.displayFieldTargets.forEach(el => el.classList.add("hidden"))
    this.formFieldTargets.forEach(el => el.classList.remove("hidden"))
    this.changePasswordSectionTarget.classList.remove("hidden")
    this.editButtonTarget.classList.add("hidden")
    this.saveButtonTarget.classList.remove("hidden")
    this.checkSensitive()
  }

  showViewMode() {
    this.displayFieldTargets.forEach(el => el.classList.remove("hidden"))
    this.formFieldTargets.forEach(el => el.classList.add("hidden"))
    this.changePasswordSectionTarget.classList.add("hidden")
    this.confirmPasswordSectionTarget.classList.add("hidden")
    this.editButtonTarget.classList.remove("hidden")
    this.saveButtonTarget.classList.add("hidden")
  }
}
