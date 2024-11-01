class MqttService
    TOPICS = {
        locker_state: "Estado_Casillero",
        connection: "Conexion",
        owner_change: "Cambio_dueno",
        model_update_start: "actualizar_modelo/inicio",
        model_update_send: "actualizar_modelo/envio",
        model_update_receive: "actualizar_modelo/recepcion",
        model_update_install: "actualizar_modelo/instalacion"
    }.freeze
  
    class << self
        def start_mqtt_subscriber
            return if @subscriber_thread&.alive?
      
            @subscriber_thread = Thread.new do
              Rails.logger.info "Iniciando suscriptor MQTT..."
              
              begin
                MqttClient.subscribe('+') do |topic, message|
                  Rails.logger.info "Procesando mensaje MQTT - Tópico: #{topic}"
                  begin
                    parsed_message = JSON.parse(message)
                    broadcast_message(topic, parsed_message)
                  rescue JSON::ParserError => e
                    Rails.logger.error "Error al parsear mensaje MQTT: #{e.message}"
                    broadcast_message(topic, message)
                  end
                end
              rescue => e
                Rails.logger.error "Error fatal en suscriptor MQTT: #{e.message}"
                Rails.logger.error e.backtrace.join("\n")
                sleep 5
                retry
              end
            end
            
            @subscriber_thread.abort_on_exception = true
          end
      def publish_locker_state(locker)
        payload = {
          casillero_id: locker.id,
          estado: locker.state ? 1 : 0,
          fecha: Time.current,
          dueno: locker.owner_email,
          controlador_id: locker.controller_id
        }.to_json
  
        MqttClient.publish(TOPICS[:locker_state], payload)
      end
  
      def publish_owner_change(locker, new_owner, password_gestures)
        payload = {
          casillero_id: locker.id,
          dueno_nuevo: new_owner,
          clave: password_gestures.map(&:id)
        }.to_json
  
        MqttClient.publish(TOPICS[:owner_change], payload)
      end
  
      def publish_model_update_start(controller, model)
        payload = {
          controlador_id: controller.id,
          modelo_id: model.id,
          tamaño: model.size_bytes,
          conexion: controller.is_connected ? "conectado" : "desconectado"
        }.to_json
  
        MqttClient.publish(TOPICS[:model_update_start], payload)
      end
  
      def publish_model_update_chunk(controller, model, chunk_data)
        payload = {
          controlador_id: controller.id,
          modelo_id: model.id,
          datos: chunk_data.unpack1('H*') # Convert binary to hex
        }.to_json
  
        MqttClient.publish(TOPICS[:model_update_send], payload)
      end
            
      private
      def broadcast_message(topic, message)
        ActionCable.server.broadcast(
          'mqtt_messages_channel',
          {
            topic: topic,
            message: message.is_a?(String) ? message : message.to_json,
            received_at: Time.current
          }
        )
      rescue => e
        Rails.logger.error "Error al transmitir mensaje MQTT: #{e.message}"
      end  
  
      def handle_mqtt_message(topic, message)
        payload = JSON.parse(message)
        
        case topic
        when TOPICS[:connection]
          handle_connection_status(payload)
        when /#{TOPICS[:model_update_receive]}/
          handle_model_update_reception(payload)
        when /#{TOPICS[:model_update_install]}/
          handle_model_update_installation(payload)
        end
      end
  
      def handle_connection_status(payload)
        controller = Controller.find_by(id: payload["controlador_id"])
        return unless controller
  
        controller.update(
          is_connected: payload["estado"] == 1,
          last_connection: Time.current
        )
      end
  
      def handle_model_update_reception(payload)
        update = ModelUpdate.find_by(
          controller_id: payload["controlador_id"],
          model_id: payload["modelo_id"]
        )
        
        return unless update
  
        if payload["estado"] == "enviado"
          update.update(status: "received")
        else
          update.update(status: "failed")
        end
      end
  
      def handle_model_update_installation(payload)
        update = ModelUpdate.find_by(
          controller_id: payload["controlador_id"],
          model_id: payload["modelo_id"]
        )
        
        return unless update
  
        if payload["estado"] == "instalado"
          update.update(status: "completed", completed_at: Time.current)
        else
          update.update(status: "failed")
        end
      end
    end
  end
  