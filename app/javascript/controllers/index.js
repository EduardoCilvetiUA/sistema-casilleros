import { application } from "./application"
import PasswordViewerController from "./password_viewer_controller"

// Importa tu controlador de dropdown
import DropdownController from "./dropdown_controller"

// Registra el controlador
application.register("dropdown", DropdownController)
application.register("password-viewer", PasswordViewerController)