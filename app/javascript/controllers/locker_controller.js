import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

export default class extends Controller {
  static targets = ["updateModal", "viewModal", "selectedGestures"]

  connect() {
    this.selectedGestures = []
    this.setupGestureButtons()
    
    // Inicializar modales con las nuevas opciones
    if (this.hasUpdateModalTarget) {
      this.updateModal = new Modal(this.updateModalTarget, {
        backdrop: 'static',
        keyboard: false
      })
    }
    
    if (this.hasViewModalTarget) {
      this.viewModal = new Modal(this.viewModalTarget, {
        backdrop: 'static',
        keyboard: false
      })
    }
    
    this.setupModalListeners()
  }

  setupModalListeners() {
    if (this.hasUpdateModalTarget) {
      this.updateModalTarget.addEventListener('hidden.bs.modal', () => this.cleanup('update'))
    }
    
    if (this.hasViewModalTarget) {
      this.viewModalTarget.addEventListener('hidden.bs.modal', () => this.cleanup('view'))
    }
  }

  cleanup(modalType) {
    if (modalType === 'update') {
      this.selectedGestures = []
      this.updateSelectedGesturesDisplay()
    }
    
    // Limpiar backdrops y restaurar body
    const backdrops = document.getElementsByClassName('modal-backdrop')
    Array.from(backdrops).forEach(backdrop => backdrop.remove())
    document.body.classList.remove('modal-open')
    document.body.style.removeProperty('overflow')
    document.body.style.removeProperty('padding-right')
  }

  handleGestureClick(event) {
    const btn = event.currentTarget
    const symbol = btn.dataset.gestureSymbol
    
    if (this.selectedGestures.length < 4) {
      this.selectedGestures.push(symbol)
      this.updateSelectedGesturesDisplay()
    }
    
    document.getElementById('updatePasswordBtn').disabled = this.selectedGestures.length !== 4
  }

  updateSelectedGesturesDisplay() {
    const container = document.getElementById('selectedGesturesContainer')
    container.innerHTML = ''
    
    for (let i = 0; i < 4; i++) {
      const div = document.createElement('div')
      div.className = 'gesture-placeholder'
      div.textContent = this.selectedGestures[i] || '_'
      container.appendChild(div)
    }
  }

  setupPasswordUpdate() {
    document.getElementById('updatePasswordBtn').addEventListener('click', () => {
      const lockerId = this.updateModalTarget.dataset.lockerId
      
      fetch(`/controllers/${this.controllerId}/lockers/${lockerId}/update_password`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector("[name='csrf-token']").content
        },
        body: JSON.stringify({
          gesture_sequence: this.selectedGestures
        })
      })
      .then(response => response.json())
      .then(data => {
        if (data.message) {
          this.updateModal.hide()
          this.selectedGestures = []
          this.updateSelectedGesturesDisplay()
          
          // Usar una notificación más elegante
          this.showNotification(data.message, 'success')
        }
      })
      .catch(error => {
        this.showNotification('Error al actualizar la contraseña', 'error')
      })
    })
  }

  setupViewPassword() {
    this.viewModalTarget.addEventListener('show.bs.modal', (event) => {
      const button = event.relatedTarget
      const lockerId = button.getAttribute('data-locker-id')
      
      fetch(`/controllers/${this.controllerId}/lockers/${lockerId}/password`)
        .then(response => response.json())
        .then(data => {
          const sequenceContainer = this.viewModalTarget.querySelector('.gesture-sequence')
          sequenceContainer.innerHTML = data.password_sequence
            .map(gesture => `<div class="gesture-display">${gesture}</div>`)
            .join('')
        })
    })
  }

  showNotification(message, type = 'success') {
    const alertDiv = document.createElement('div')
    alertDiv.className = `alert alert-${type} alert-dismissible fade show`
    alertDiv.role = 'alert'
    alertDiv.innerHTML = `
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    `
    document.body.appendChild(alertDiv)
    
    setTimeout(() => {
      alertDiv.remove()
    }, 3000)
  }

  // Métodos para manejar el modal
  openModal(modalName) {
    this[`${modalName}Modal`].show()
  }

  closeModal(modalName) {
    this[`${modalName}Modal`].hide()
  }
  disconnect() {
    if (this.updateModal) {
      this.updateModal.dispose()
    }
    if (this.viewModal) {
      this.viewModal.dispose()
    }
    this.cleanup()
  }

}