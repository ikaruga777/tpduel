import { Controller } from "@hotwired/stimulus"

// Copies the share URL to the clipboard with a small "copied!" confirmation.
export default class extends Controller {
  static targets = ["source", "button"]
  static values = { text: String }

  async copy() {
    const text = this.hasTextValue ? this.textValue : this.sourceTarget.value
    try {
      await navigator.clipboard.writeText(text)
    } catch (_e) {
      // Fallback for non-secure contexts.
      this.sourceTarget.select()
      document.execCommand("copy")
    }
    this.flash("コピーしました！")
  }

  flash(message) {
    if (!this.hasButtonTarget) return
    const original = this.buttonTarget.textContent
    this.buttonTarget.textContent = message
    this.buttonTarget.disabled = true
    setTimeout(() => {
      this.buttonTarget.textContent = original
      this.buttonTarget.disabled = false
    }, 1200)
  }
}
