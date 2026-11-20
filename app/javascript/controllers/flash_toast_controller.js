import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.startDismissTimer()
  }

  disconnect() {
    this.clearDismissTimer()
  }

  startDismissTimer() {
    this.clearDismissTimer()
    this.dismissTimeout = setTimeout(() => {
      this.dismiss()
    }, 5500)
  }

  clearDismissTimer() {
    if (this.dismissTimeout) {
      clearTimeout(this.dismissTimeout)
      this.dismissTimeout = null
    }
  }

  pauseTimer() {
    this.clearDismissTimer()
  }

  resumeTimer() {
    this.startDismissTimer()
  }

  dismiss() {
    this.clearDismissTimer()
    this.element.classList.add("flash-toast--dismissing")
    setTimeout(() => {
      this.element.remove()
      const container = document.getElementById("flash-toast-container")
      if (container && container.querySelectorAll(".flash-toast").length === 0) {
        container.remove()
      }
    }, 300)
  }
}
