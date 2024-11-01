import "@hotwired/turbo-rails"
import * as bootstrap from "bootstrap"
import "controllers"

// Hacer bootstrap disponible globalmente
window.bootstrap = bootstrap

// Función para limpiar modales
function cleanupModals() {
  const backdrops = document.querySelectorAll('.modal-backdrop')
  backdrops.forEach(backdrop => backdrop.remove())
  
  const modals = document.querySelectorAll('.modal')
  modals.forEach(modal => {
    modal.classList.remove('show')
    modal.style.display = 'none'
  })
  
  document.body.classList.remove('modal-open')
  document.body.style.removeProperty('overflow')
  document.body.style.removeProperty('padding-right')
}

// Limpiar modales antes de cachear y al cargar la página
document.addEventListener('turbo:before-cache', cleanupModals)
document.addEventListener('DOMContentLoaded', cleanupModals)

// Manejar modales cuando se navega con Turbo
document.addEventListener('turbo:before-render', cleanupModals)
document.addEventListener('turbo:render', () => {
  document.querySelectorAll('[data-controller="modal"]').forEach(element => {
    const modal = new bootstrap.Modal(element)
    if (element.classList.contains('show')) {
      modal.show()
    }
  })
})