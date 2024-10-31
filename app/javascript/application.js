import "@hotwired/turbo-rails"
import * as bootstrap from "bootstrap"
import "controllers"

// Make bootstrap globally available
window.bootstrap = bootstrap

// Limpiar backdrops en navegación Turbo
document.addEventListener('turbo:before-cache', () => {
  const backdrops = document.querySelectorAll('.modal-backdrop')
  backdrops.forEach(backdrop => backdrop.remove())
  
  document.body.classList.remove('modal-open')
  document.body.style.removeProperty('overflow')
  document.body.style.removeProperty('padding-right')
})

// Limpiar backdrops en carga de página
document.addEventListener('DOMContentLoaded', () => {
  const backdrops = document.querySelectorAll('.modal-backdrop')
  backdrops.forEach(backdrop => backdrop.remove())
  
  document.body.classList.remove('modal-open')
  document.body.style.removeProperty('overflow')
  document.body.style.removeProperty('padding-right')
})