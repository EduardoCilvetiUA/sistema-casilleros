// app/javascript/controllers/sync_controller.js
import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

export default class extends Controller {
  static targets = ["status"]

  connect() {
    this.subscribeToMqttMessages()
  }

  initiate(event) {
    event.preventDefault()
    const form = event.target
    
    // Deshabilitar el botón durante la sincronización
    const button = form.querySelector('button[type="submit"]')
    button.disabled = true
    
    // Mostrar indicador de carga
    const icon = button.querySelector('i')
    icon.className = 'fas fa-spinner fa-spin me-1'
    
    form.requestSubmit()
  }

  subscribeToMqttMessages() {
    consumer.subscriptions.create("MqttMessagesChannel", {
      received: (data) => {
        if (data.topic === "sincronizacion") {
          this.handleSyncMessage(JSON.parse(data.message))
        }
      }
    })
  }

  handleSyncMessage(data) {
    const statusElement = document.querySelector(`[data-controller-id="${data.controller_id}"]`)
    if (statusElement) {
      // Restaurar estado del botón
      const button = statusElement.closest('.card').querySelector('button[type="submit"]')
      if (button) {
        button.disabled = false
        const icon = button.querySelector('i')
        icon.className = 'fas fa-sync me-1'
      }
      
      // Actualizar estado de conexión
      if (data.status === "sincronizado") {
        location.reload() // O actualizar el estado sin recargar usando Turbo
      }
    }
  }
}