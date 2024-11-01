import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

export default class extends Controller {
  connect() {
    // Eliminar cualquier backdrop existente al conectar
    this.cleanup()
    
    // Inicializar el modal
    this.modal = new Modal(this.element, {
      backdrop: 'static', // Previene cerrar al hacer clic fuera
      keyboard: true      // Permite cerrar con ESC
    })
    
    // Add event listener for bootstrap modal hide event
    this.element.addEventListener('hidden.bs.modal', () => {
      this.cleanup()
    })
  }

  disconnect() {
    if (this.modal) {
      this.modal.dispose()
    }
    this.cleanup()
  }

  open() {
    if (this.modal) {
      this.modal.show()
    }
  }

  close() {
    if (this.modal) {
      this.modal.hide()
      this.cleanup()
    }
  }

  cleanup() {
    // Eliminar todos los backdrops
    const backdrops = document.querySelectorAll('.modal-backdrop')
    backdrops.forEach(backdrop => backdrop.remove())
    
    // Limpiar clases y estilos del body
    document.body.classList.remove('modal-open')
    document.body.style.removeProperty('overflow')
    document.body.style.removeProperty('padding-right')
  }

  submitForm(event) {
    event.preventDefault()
    const form = event.currentTarget
    
    // Validar el formulario antes de enviarlo
    if (form.checkValidity()) {
      form.submit()
      this.close()
    } else {
      form.reportValidity()
    }
  }

  // Add this method to handle data-bs-dismiss
  handleDismiss(event) {
    if (event.target.hasAttribute('data-bs-dismiss')) {
      this.close()
    }
  }
}