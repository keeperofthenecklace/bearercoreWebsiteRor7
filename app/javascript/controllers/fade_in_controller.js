import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const elements = this.element.querySelectorAll(".reveal")

    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-visible")
            this.observer.unobserve(entry.target)
          }
        })
      },
      { threshold: 0, rootMargin: "0px 0px -40px 0px" }
    )

    elements.forEach((el) => {
      el.classList.add("reveal-ready")
      this.observer.observe(el)
    })
  }

  disconnect() {
    this.observer?.disconnect()
  }
}
