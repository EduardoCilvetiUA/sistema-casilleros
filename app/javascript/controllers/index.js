import { application } from "./application"

// Import controllers
import LockerController from "./locker_controller.js"
import PasswordViewerController from "./password_viewer_controller.js"
import GesturesViewerController from "./gestures_viewer_controller.js"
import DropdownController from "./dropdown_controller.js"
import ModalController from "./modal_controller.js"

// Register controllers with explicit logging
console.log("📝 Starting controller registration...")

// Logging detallado para el controlador Locker
console.log("🔍 LockerController:", LockerController)
console.log("🔍 application:", application)

try {
  if (!LockerController) {
    throw new Error("LockerController is undefined")
  }
  application.register("locker", LockerController)
  console.log("✅ Locker controller registered successfully")
} catch (error) {
  console.error("❌ Error registering Locker controller:", error)
  console.error("Stack:", error.stack)
}

try {
  application.register("password-viewer", PasswordViewerController)
  console.log("✅ PasswordViewer controller registered successfully")
} catch (error) {
  console.error("❌ Error registering PasswordViewer controller:", error)
}

try {
  application.register("gestures-viewer", GesturesViewerController)
  console.log("✅ GesturesViewer controller registered successfully")
} catch (error) {
  console.error("❌ Error registering GesturesViewer controller:", error)
}

try {
  application.register("dropdown", DropdownController)
  console.log("✅ Dropdown controller registered successfully")
} catch (error) {
  console.error("❌ Error registering Dropdown controller:", error)
}

try {
  application.register("modal", ModalController)
  console.log("✅ Modal controller registered successfully")
} catch (error) {
  console.error("❌ Error registering Modal controller:", error)
}

console.log("📝 Controller registration completed")