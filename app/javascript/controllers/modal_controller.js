import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

export default class extends Controller {
  connect() {
    // No inicializar el modal aquí para evitar duplicación
  }

  disconnect() {
    this.removeBackdrop()
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }
    
    const modal = Modal.getInstance(this.element) || new Modal(this.element)
    modal.hide()
    
    // Remover backdrop inmediatamente después de cerrar
    setTimeout(() => this.removeBackdrop(), 200)
  }

  removeBackdrop() {
    // Remover todos los backdrops
    const backdrops = document.querySelectorAll('.modal-backdrop')
    backdrops.forEach(backdrop => backdrop.remove())
    
    // Limpiar las clases y estilos del body
    document.body.classList.remove('modal-open')
    document.body.style.removeProperty('overflow')
    document.body.style.removeProperty('padding-right')
  }

  submitForm(event) {
    const modal = Modal.getInstance(this.element)
    if (modal) {
      modal.hide()
      this.removeBackdrop()
    }
  }
}