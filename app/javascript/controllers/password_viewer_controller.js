import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sequence"]

  connect() {
    console.log("🔌 PasswordViewer conectado")
  }

  handleModalShow(event) {
    console.log("🎯 Modal mostrado")
    const button = event.relatedTarget
    
    if (!button) {
      console.error("No se encontró el botón activador")
      return
    }

    const lockerId = button.getAttribute('data-locker-id')
    const controllerId = button.getAttribute('data-controller-id')
    
    console.log("📝 Datos:", { lockerId, controllerId })
    
    if (!this.hasSequenceTarget) {
      console.error("No se encontró el target de secuencia")
      return
    }
    
    // Mostrar loading
    this.sequenceTarget.innerHTML = `
      <div class="d-flex justify-content-center">
        <div class="spinner-border text-light" role="status">
          <span class="visually-hidden">Cargando...</span>
        </div>
      </div>
    `

    // Cargar la contraseña
    fetch(`/controllers/${controllerId}/lockers/${lockerId}/password`, {
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => {
      if (!response.ok) {
        throw new Error(`Error HTTP: ${response.status}`)
      }
      return response.json()
    })
    .then(data => {
      console.log("📦 Datos recibidos:", data)
      
      if (data.password_sequence && Array.isArray(data.password_sequence)) {
        this.sequenceTarget.innerHTML = `
          <div class="d-flex justify-content-center gap-3">
            ${data.password_sequence.map(symbol => `
              <div class="gesture-display p-3 border rounded bg-secondary">
                <span class="fs-1">${symbol}</span>
              </div>
            `).join('')}
          </div>
        `
      } else {
        throw new Error('Formato de respuesta inválido')
      }
    })
    .catch(error => {
      console.error("❌ Error:", error)
      this.sequenceTarget.innerHTML = `
        <div class="alert alert-danger">
          <i class="fas fa-exclamation-triangle me-2"></i>
          ${error.message}
        </div>
      `
    })
  }
}