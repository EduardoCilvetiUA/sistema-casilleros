require 'omniauth/strategies/google_oauth2'

OmniAuth.config.allowed_request_methods = [:post]
OmniAuth.config.silence_get_warning = true
OmniAuth.config.request_validation_phase = proc{} # Añade esta línea