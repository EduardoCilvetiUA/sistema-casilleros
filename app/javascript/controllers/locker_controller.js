import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

// Asegurar que la clase tiene un nombre y es exportada correctamente
export default class LockerController extends Controller {
  static targets = ["modal", "container", "sequenceDisplay", "updateButton", "ownerModal", "ownerEmailInput"]
  static values = {
    maxLength: { type: Number, default: 4 }
  }

  initialize() {
    console.log("🎯 Locker controller initializing")
  }

  connect() {
    console.log("🔌 Locker controller connected")
    this.currentSequence = []
    
    // Log available targets
    console.log("Available targets:", {
      modal: this.hasModalTarget,
      container: this.hasContainerTarget,
      sequenceDisplay: this.hasSequenceDisplayTarget,
      updateButton: this.hasUpdateButtonTarget
    })
  }

  handleModalShow(event) {
    console.log("📂 Modal showing")
    const button = event.relatedTarget
    this.lockerId = button.getAttribute('data-locker-id')
    this.controllerId = button.getAttribute('data-controller-id')
    console.log("IDs:", { lockerId: this.lockerId, controllerId: this.controllerId })
    this.clearSequence()
  }

  addGestureToSequence(event) {
    event.preventDefault()
    console.log("👆 Gesture clicked")
    
    if (this.currentSequence.length >= this.maxLengthValue) {
      console.log("⚠️ Sequence full")
      return
    }
    
    const gesture = event.currentTarget.dataset.lockerGestureSymbol
    console.log("Gesture:", gesture)
    
    if (gesture) {
      this.currentSequence.push(gesture)
      this.updateSequenceDisplay()
      console.log("Current sequence:", this.currentSequence)
    }
  }

  clearSequence(event) {
    if (event) event.preventDefault()
    console.log("🧹 Clearing sequence")
    this.currentSequence = []
    this.updateSequenceDisplay()
  }

  updateSequenceDisplay() {
    if (!this.hasSequenceDisplayTarget) {
      console.error("❌ No sequence display target found")
      return
    }
    
    console.log("🔄 Updating display")
    const slots = this.sequenceDisplayTarget.querySelectorAll('[data-locker-slot]')
    
    slots.forEach((slot, index) => {
      if (this.currentSequence[index]) {
        slot.textContent = this.currentSequence[index]
        slot.classList.add('filled')
      } else {
        slot.textContent = '_'
        slot.classList.remove('filled')
      }
    })

    if (this.hasUpdateButtonTarget) {
      this.updateButtonTarget.disabled = this.currentSequence.length !== this.maxLengthValue
      console.log("Button state:", !this.updateButtonTarget.disabled)
    }
  }

  updatePassword() {
    if (!this.lockerId || !this.controllerId) {
      console.error("Missing IDs")
      return
    }
  
    if (this.currentSequence.length !== this.maxLengthValue) {
      console.error("Incomplete sequence")
      return
    }
  
    // Deshabilitar el botón para prevenir múltiples clics
    this.updateButtonTarget.disabled = true
  
    fetch(`/controllers/${this.controllerId}/lockers/${this.lockerId}/update_password`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector("[name='csrf-token']").content
      },
      body: JSON.stringify({
        gesture_sequence: this.currentSequence
      })
    })
    .then(response => response.json())
    .then(data => {
      if (data.message) {
        this.showNotification(data.message, 'success')
        if (this.modalTarget) {
          const modal = bootstrap.Modal.getInstance(this.modalTarget)
          if (modal) {
            modal.hide()
          }
        }
      }
    })
    .catch(error => {
      console.error("Error:", error)
      this.showNotification('Error al actualizar la contraseña', 'error')
    })
    .finally(() => {
      // Habilitar el botón nuevamente
      this.updateButtonTarget.disabled = false
    })
  }

  showNotification(message, type = 'success') {
    const alertDiv = document.createElement('div')
    alertDiv.className = `alert alert-${type} alert-dismissible fade show fixed-top mx-auto mt-3`
    alertDiv.style.maxWidth = '500px'
    alertDiv.role = 'alert'
    alertDiv.innerHTML = `
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    `
    document.body.appendChild(alertDiv)
    
    setTimeout(() => alertDiv.remove(), 3000)
  }

  handleOwnerModalShow(event) {
    const button = event.relatedTarget
    this.lockerId = button.getAttribute('data-locker-id')
    this.controllerId = button.getAttribute('data-controller-id')
    this.ownerEmailInputTarget.value = ''
  }

  updateOwner(event) {
    event.preventDefault()
    const ownerEmail = this.ownerEmailInputTarget.value
    fetch(`/controllers/${this.controllerId}/lockers/${this.lockerId}/update_owner`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ owner_email: ownerEmail })
    })
      .then(response => response.json())
      .then(data => {
        if (data.message) {
          // Close modal and show success notification
          const modal = bootstrap.Modal.getInstance(this.ownerModalTarget)
          modal.hide()
          this.showNotification(data.message, 'success')
          // Optionally reload the page if necessary
          location.reload()
        } else if (data.error) {
          // Show error notification
          this.showNotification(data.error, 'error')
        }
      })
      .catch(error => {
        console.error('Error:', error)
        this.showNotification('Error al actualizar el propietario', 'error')
      })
  }
}