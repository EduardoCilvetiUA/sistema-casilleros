import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sequence"]

  connect() {
    // Se ejecuta cuando el controlador se conecta
  }

  loadPassword(event) {
    const triggerButton = event.relatedTarget
    const lockerId = triggerButton.getAttribute('data-locker-id')
    const controllerId = triggerButton.getAttribute('data-controller-id')

    fetch(`/controllers/${controllerId}/lockers/${lockerId}/password`)
      .then(response => response.json())
      .then(data => {
        // Actualiza el contenido del modal con la contraseña
        this.sequenceTarget.textContent = data.password
      })
      .catch(error => {
        console.error('Error al obtener la contraseña:', error)
      })
  }
}