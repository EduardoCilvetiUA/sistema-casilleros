import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sequence"]

  connect() {
    console.log("🔌 GesturesViewer conectado")
  }

  handleModalShow(event) {
    console.log("🎯 Modal mostrado")
    const button = event.relatedTarget
    
    if (!button) {
      console.error("No se encontró el botón activador")
      return
    }

    const modelId = button.getAttribute('data-model-id')
    console.log("📝 Datos:", { modelId })
    
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

    // Cargar los gestos
    fetch(`/models/${modelId}/gestos`, {
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => {
      if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`)
      return response.json()
    })
    .then(data => {
      console.log("📦 Gestos recibidos:", data)
      if (data.gestures) {
        this.sequenceTarget.innerHTML = `
          <div class="d-flex justify-content-center gap-3 flex-wrap">
            ${data.gestures.map(gesture => `
              <div class="gesture-display p-3 border rounded bg-secondary">
                <div class="fs-1">${gesture.symbol}</div>
                <div class="small text-light">${gesture.name}</div>
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
          Error al cargar los gestos: ${error.message}
        </div>
      `
    })
  }
}