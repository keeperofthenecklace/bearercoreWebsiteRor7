import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "formState", "successState", "submitBtn", "errorMsg"]

  open(event) {
    event.preventDefault()
    this.overlayTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  close() {
    this.overlayTarget.classList.add("hidden")
    document.body.style.overflow = ""
    setTimeout(() => this._reset(), 300)
  }

  closeOnBackdrop(event) {
    if (event.target === this.overlayTarget) this.close()
  }

  async submit(event) {
    event.preventDefault()
    const form = event.target
    const btn  = this.submitBtnTarget

    btn.disabled    = true
    btn.textContent = "Submitting…"
    if (this.hasErrorMsgTarget) this.errorMsgTarget.classList.add("hidden")

    try {
      const res = await fetch(form.action, {
        method:  "POST",
        body:    new FormData(form),
        headers: {
          "Accept":           "application/json",
          "X-CSRF-Token":     document.querySelector('meta[name="csrf-token"]')?.content,
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (res.ok) {
        this.formStateTarget.classList.add("hidden")
        this.successStateTarget.classList.remove("hidden")
      } else {
        const data = await res.json().catch(() => ({}))
        this._showError(data.errors?.join(". ") || "Please check your details and try again.")
        btn.disabled    = false
        btn.textContent = "Submit Briefing Request"
      }
    } catch {
      this._showError("A network error occurred. Please try again.")
      btn.disabled    = false
      btn.textContent = "Submit Briefing Request"
    }
  }

  _reset() {
    this.formStateTarget.classList.remove("hidden")
    this.successStateTarget.classList.add("hidden")
    this.element.querySelector("form")?.reset()
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.disabled    = false
      this.submitBtnTarget.textContent = "Submit Briefing Request"
    }
    if (this.hasErrorMsgTarget) this.errorMsgTarget.classList.add("hidden")
  }

  _showError(msg) {
    if (this.hasErrorMsgTarget) {
      this.errorMsgTarget.textContent = msg
      this.errorMsgTarget.classList.remove("hidden")
    }
  }
}
