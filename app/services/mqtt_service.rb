# app/services/mqtt_service.rb
class MqttService
  TOPICS = {
    locker_state: "Estado_Casillero",
    password_change: "Password_change",
    connection: "Conexion",
    owner_change: "Owner_change",
    model_update: "Cambio_modelo",
    sync: "sincronizacion",
    status_locker: "status_locker",  # New topic
    subscription_receiver: "subscription_receiver"  # New topic
  }.freeze

  SUBSCRIPTION_TOPICS = [
    TOPICS[:locker_state],
    TOPICS[:connection],
    TOPICS[:status_locker],
    TOPICS[:subscription_receiver]
  ].freeze

  QOS_LEVELS = {
    critical: 2,    # Para actualizaciones de modelo
    important: 1,   # Para sincronización y cambios de dueño
    standard: 0     # Para estados de casilleros
  }.freeze

  VALID_TOPICS = TOPICS.values.freeze

  class << self
    def processed_messages
      @processed_messages ||= {}
    end

    def publish_connection_test(controller)
      payload = {
        controlador_name: controller.name,
        estado: 1,
        timestamp: Time.current.iso8601,
        tipo: "test_conexion"
      }

      publish_message(TOPICS[:connection], payload, QOS_LEVELS[:important])
    end

    def start_mqtt_subscriber
      # Subscribe to all topics at once with a single connection
      MqttClient.subscribe(SUBSCRIPTION_TOPICS, qos: QOS_LEVELS[:standard]) do |topic, message|
        begin
          parsed_message = JSON.parse(message)
          next unless valid_message?(topic, parsed_message)

          handle_mqtt_message(topic, parsed_message)
        rescue JSON::ParserError => e
          Rails.logger.error "Error parsing MQTT message: #{e.message}"
        end
      end
    end

    def publish_locker_state(locker)
      payload = {
        casillero_number: locker.number,
        estado: locker.state ? 1 : 0,
        fecha: Time.current.iso8601,
        dueno: locker.owner_email,
        controlador_id: locker.controller_id
      }

      publish_message(TOPICS[:locker_state], payload, QOS_LEVELS[:standard])
    end

    def publish_owner_change(locker, new_owner, password_gestures)
      payload = {
        controller_name: locker.controller.name,
        casillero_number: locker.number,
        dueno_nuevo: new_owner,
        clave: password_gestures.map(&:id),
        tipo: "creacion"
      }

      # Remove the mailer call from here
      publish_message(TOPICS[:owner_change], payload, QOS_LEVELS[:important])
    end

    def publish_password_change(locker, new_password)
      payload = {
        controller_name: locker.controller.name,
        casillero_number: locker.number,
        new_password: new_password,
        tipo: "update"
      }

      # Remove the mailer call from here
      publish_message(TOPICS[:password_change], payload, QOS_LEVELS[:important])
    end

    def publish_model_change(controller, old_model, new_model)
      payload = {
        controller_name: controller.name,
        old_model: old_model.name,
        new_model: new_model.name,
        timestamp: Time.current.iso8601
      }.to_json

      MqttClient.publish(
        TOPICS[:model_update],
        payload,
        qos: QOS_LEVELS[:important]
      )
    end

    def publish_model_update_start(controller, model)
      payload = {
        controlador_id: controller.id,
        modelo_id: model.id,
        tamaño: model.size_bytes,
        conexion: controller.is_connected ? "conectado" : "desconectado"
      }

      publish_message(TOPICS[:model_update_start], payload, QOS_LEVELS[:critical])
    end

    def publish_sync_request(controller)
      Rails.logger.info "Iniciando solicitud de sincronización para controlador #{controller.id}"

      payload = {
        controlador_id: controller.id,
        timestamp: Time.current.iso8601,
        tipo: "solicitud_sync",
        estado: "pendiente",
        nombre: controller.name,
        ubicacion: controller.location
      }

      success = publish_message(TOPICS[:sync], payload, QOS_LEVELS[:important])

      if success
        controller.update_connection_status(true)
        Rails.logger.info "Solicitud de sincronización enviada exitosamente"
        true
      else
        Rails.logger.error "Fallo al enviar solicitud de sincronización"
        false
      end
    end

    private

    def get_topic_qos(topic)
      case topic
      when TOPICS[:model_update_start], TOPICS[:model_update_send],
           TOPICS[:model_update_receive], TOPICS[:model_update_install]
        QOS_LEVELS[:critical]
      when TOPICS[:sync], TOPICS[:owner_change]
        QOS_LEVELS[:important]
      else
        QOS_LEVELS[:standard]
      end
    end

    def message_processed?(message_id)
      false
    end

    def mark_message_processed(message_id, time)
      processed_messages[message_id] = time  # Usar el método processed_messages en lugar de @processed_messages

      # Limpiar mensajes antiguos
      processed_messages.delete_if { |_, processed_time| Time.current - processed_time > 1.hour }
    end

    def publish_message(topic, payload, qos, retain: false)
      Rails.logger.info "Publicando en tópico: #{topic} (QoS: #{qos})"

      begin
        MqttClient.publish(topic, payload.to_json, qos: qos, retain: false)
        true
      rescue => e
        Rails.logger.error "Error al publicar mensaje MQTT: #{e.message}"
        false
      end
    end

    def valid_message?(topic, message)
      case topic
      when TOPICS[:locker_state]
        %w[casillero_id estado controlador_id].all? { |key| message.key?(key) }
      when TOPICS[:connection]
        %w[controlador_id estado].all? { |key| message.key?(key) }
      when TOPICS[:status_locker]
        %w[locker_id status].all? { |key| message.key?(key) }
      when TOPICS[:owner_change]
        required_keys = %w[casillero_id dueno_nuevo clave]
        required_keys.all? { |key| message.key?(key) }
      when TOPICS[:sync]
        %w[controlador_id tipo].all? { |key| message.key?(key) }
      when TOPICS[:model_update_start], TOPICS[:model_update_send]
        %w[controlador_id modelo_id].all? { |key| message.key?(key) }
      when TOPICS[:subscription_receiver]
        %w[casillero_id].all? { |key| message.key?(key) }
      else
        false
      end
    end

    def handle_mqtt_message(topic, message)
      message_id = "#{topic}-#{message.hash}"
      current_time = Time.current

      # Solo procesar si el mensaje no ha sido procesado en los últimos X segundos
      if recently_processed?(message_id)
        Rails.logger.info "Mensaje recibido pero ignorado por ser muy reciente: #{message}"
        return
      end

      mark_message_processed(message_id, current_time)

      case topic
      when TOPICS[:sync]
        handle_sync_response(message)
      when TOPICS[:connection]
        handle_connection_status(message)
      when TOPICS[:locker_state]
        handle_locker_state(message)
      when TOPICS[:owner_change]
        handle_owner_change(message)
      when TOPICS[:model_update_receive]
        handle_model_update_reception(message)
      when TOPICS[:model_update_install]
        handle_model_update_installation(message)
      when TOPICS[:status_locker]
        handle_locker_status(message)
      when TOPICS[:subscription_receiver]
        handle_subscription_receiver(message)
      end
      rescue => e
        Rails.logger.error "Error procesando mensaje MQTT: #{e.message}"
    end
    def recently_processed?(message_id)
      last_processed = processed_messages[message_id]  # Usar el método processed_messages en lugar de @processed_messages
      return false if last_processed.nil?

      # Definir ventana de tiempo (por ejemplo, 5 segundos)
      Time.current - last_processed < 5.seconds
    end

    def handle_sync_response(data)
      return unless data["controlador_id"]

      controller = Controller.find_by(id: data["controlador_id"])
      return unless controller

      controller.update(
        is_connected: true,
        last_connection: Time.current
      )

      broadcast_message(TOPICS[:sync], {
        controller_id: controller.id,
        status: "sincronizado",
        timestamp: Time.current.iso8601
      })
    end

    def handle_locker_state(data)
      return unless data["casillero_id"]

      locker = Locker.find_by(id: data["casillero_id"])
      return unless locker

      locker.update(state: data["estado"] == 1)
      broadcast_message(TOPICS[:locker_state], data)
    end

    def handle_connection_status(data)
      return unless data["controlador_id"]

      controller = Controller.find_by(id: data["controlador_id"])
      return unless controller

      controller.update(
        is_connected: data["estado"] == 1,
        last_connection: Time.current
      )
    end

    def handle_model_update_reception(data)
      update = ModelUpdate.find_by(
        controller_id: data["controlador_id"],
        model_id: data["modelo_id"]
      )

      return unless update

      update.update(
        status: data["estado"] == "enviado" ? "received" : "failed"
      )
    end

    def handle_model_update_installation(data)
      update = ModelUpdate.find_by(
        controller_id: data["controlador_id"],
        model_id: data["modelo_id"]
      )

      return unless update

      if data["estado"] == "instalado"
        update.update(status: "completed", completed_at: Time.current)
      else
        update.update(status: "failed")
      end
    end

    def broadcast_message(topic, message)
      ActionCable.server.broadcast(
        "mqtt_messages_channel",
        {
          topic: topic,
          message: message.to_json,
          received_at: Time.current
        }
      )
    rescue => e
      Rails.logger.error "Error al transmitir mensaje MQTT: #{e.message}"
    end
    def handle_owner_change(data)
      return unless data["casillero_id"]

      locker = Locker.find_by(id: data["casillero_id"])
      return unless locker

      # No procesar si es el mensaje que nosotros mismos enviamos
      return if data["tipo"] == "creacion"

      begin
        # Registrar el evento
        LockerEvent.create!(
          locker: locker,
          event_type: "owner_change",
          success: true,
          event_time: Time.current
        )

        broadcast_message(TOPICS[:owner_change], {
          casillero_id: locker.id,
          status: "actualizado",
          timestamp: Time.current.iso8601
        })
      rescue => e
        Rails.logger.error "Error procesando cambio de dueño: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end

    def handle_locker_status(data)
      locker = Locker.find_by(id: data["locker_id"])

      if locker.nil?
        Rails.logger.warn "No se encontró el casillero con ID: #{data["locker_id"]}"
        return
      end

      if locker.owner_email.blank?
        Rails.logger.warn "Casillero #{data["locker_id"]} no tiene email de propietario configurado"
        return
      end

      # Send email to locker owner
      LockerMailer.status_notification(locker, data["status"]).deliver_later

      if data["status"] == "open"
        locker.update(state: true)
        LockerEvent.create!(
          locker: locker,
          event_type: "open",
          success: true,
          event_time: Time.current
        )
      elsif data["status"] == "closed"
        locker.update(state: false)
      end

      broadcast_message(TOPICS[:status_locker], {
        locker_id: locker.id,
        status: data["status"],
        timestamp: Time.current.iso8601
      })
    rescue => e
      Rails.logger.error "Error handling locker status: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
    def handle_subscription_receiver(data)
      return unless data["casillero_id"]

      locker = Locker.find_by(id: data["casillero_id"])
      return unless locker

      # Notify the user about the password change confirmation
      ActionCable.server.broadcast(
        "mqtt_messages_channel",
        {
          topic: TOPICS[:subscription_receiver],
          message: data.to_json,
          received_at: Time.current
        }
      )
    rescue => e
      Rails.logger.error "Error handling subscription receiver: #{e.message}"
    end
  end
end
