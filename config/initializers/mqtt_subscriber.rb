Rails.application.config.after_initialize do
    if defined?(Rails::Server)
      Thread.new do
        sleep 10 # Dar más tiempo para que el servidor se inicialice completamente
        begin
          MqttService.start_mqtt_subscriber
        rescue => e
          Rails.logger.error "Error al iniciar suscriptor MQTT: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
        end
      end
    end
  end