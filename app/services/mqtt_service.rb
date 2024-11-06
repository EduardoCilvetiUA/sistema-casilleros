# app/services/mqtt_service.rb
class MqttService
  TOPICS = {
    locker_state: "Estado_Casillero",
    connection: "Conexion",
    owner_change: "Cambio_dueno",
    model_update_start: "actualizar_modelo/inicio",
    model_update_send: "actualizar_modelo/envio",
    model_update_receive: "actualizar_modelo/recepcion",
    model_update_install: "actualizar_modelo/instalacion",
    sync: "sincronizacion"
  }.freeze

  QOS_LEVELS = {
    critical: 2,    # Para actualizaciones de modelo
    important: 1,   # Para sincronización y cambios de dueño
    standard: 0     # Para estados de casilleros
  }.freeze

  VALID_TOPICS = TOPICS.values.freeze

  class << self
    def processed_messages
      @processed_messages ||= Set.new
    end

    def publish_connection_test(controller)
      payload = {
        controlador_id: controller.id,
        estado: 1,
        timestamp: Time.current.iso8601,
        tipo: "test_conexion"
      }

      publish_message(TOPICS[:connection], payload, QOS_LEVELS[:important])
    end

    def start_mqtt_subscriber
      VALID_TOPICS.each do |topic|
        MqttClient.subscribe(topic, qos: get_topic_qos(topic)) do |t, message|
          begin
            parsed_message = JSON.parse(message)
            next unless valid_message?(t, parsed_message)
            
            handle_mqtt_message(t, parsed_message)
          rescue JSON::ParserError => e
            Rails.logger.error "Error parsing MQTT message: #{e.message}"
          end
        end
      end
    end

    def publish_locker_state(locker)
      payload = {
        casillero_id: locker.id,
        estado: locker.state ? 1 : 0,
        fecha: Time.current.iso8601,
        dueno: locker.owner_email,
        controlador_id: locker.controller_id
      }

      publish_message(TOPICS[:locker_state], payload, QOS_LEVELS[:standard])
    end

    def publish_owner_change(locker, new_owner, password_gestures)
      payload = {
        casillero_id: locker.id,
        dueno_nuevo: new_owner,
        clave: password_gestures.map(&:id),
        tipo: "creacion"
      }
    
      # Remove the mailer call from here
      publish_message(TOPICS[:owner_change], payload, QOS_LEVELS[:important])
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
      processed_messages.include?(message_id)
    end
  
    def mark_message_processed(message_id)
      processed_messages.add(message_id)
      # Limpiar mensajes antiguos después de cierto tiempo
      processed_messages.clear if processed_messages.size > 1000
    end
    def publish_message(topic, payload, qos, retain: false)
      Rails.logger.info "Publicando en tópico: #{topic} (QoS: #{qos})"
      
      begin
        MqttClient.publish(topic, payload.to_json, qos: qos, retain: retain)
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
      when TOPICS[:owner_change]
        required_keys = %w[casillero_id dueno_nuevo clave]
        required_keys.all? { |key| message.key?(key) }
      when TOPICS[:sync]
        %w[controlador_id tipo].all? { |key| message.key?(key) }
      when TOPICS[:model_update_start], TOPICS[:model_update_send]
        %w[controlador_id modelo_id].all? { |key| message.key?(key) }
      else
        false
      end
    end

    def handle_mqtt_message(topic, message)
      message_id = "#{topic}-#{message.hash}"
      return if message_processed?(message_id)
      mark_message_processed(message_id)
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
      end
      rescue => e
        Rails.logger.error "Error procesando mensaje MQTT: #{e.message}"
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
        'mqtt_messages_channel',
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
          event_type: 'owner_change',
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
  end
end