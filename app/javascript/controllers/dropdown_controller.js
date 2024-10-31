import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Initialize all dropdowns when the controller connects
    const dropdownElementList = [this.element]
    const dropdownList = dropdownElementList.map(dropdownEl => {
      return new bootstrap.Dropdown(dropdownEl)
    })
  }

  disconnect() {
    // Clean up the dropdown when the controller disconnects
    const dropdown = bootstrap.Dropdown.getInstance(this.element)
    if (dropdown) {
      dropdown.dispose()
    }
  }
}