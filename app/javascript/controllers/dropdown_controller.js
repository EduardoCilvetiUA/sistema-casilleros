import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

export default class extends Controller {
  connect() {
    console.log("🔌 Dropdown controller connected")
    // Verificar que bootstrap.Dropdown está disponible
    if (bootstrap && bootstrap.Dropdown) {
      this.dropdown = new bootstrap.Dropdown(this.element)
    } else {
      console.error("❌ Bootstrap Dropdown no está disponible")
    }
  }

  disconnect() {
    if (this.dropdown) {
      this.dropdown.dispose()
    }
  }
}