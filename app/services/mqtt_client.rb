require 'mqtt'

class MqttClient
  DEFAULT_HOST = 'b5b41cc0167e4c55bcc0f695f9b033ca.s1.eu.hivemq.cloud'
  DEFAULT_PORT = 8883
  TIMEOUT = 15
  RECONNECT_DELAY = 5

  class << self
    def publish(topic, payload, qos: 0, retain: false)
      Rails.logger.info "Iniciando publicación MQTT - Tópico: #{topic}, QoS: #{qos}"
      Rails.logger.debug "Payload: #{payload}"
      
      begin
        client = connect
        
        if client.connected?
          Rails.logger.info "Cliente conectado, publicando mensaje..."
          client.publish(topic, payload, retain: retain, qos: qos)
          Rails.logger.info "Mensaje publicado exitosamente"
          true
        else
          Rails.logger.error "No se pudo establecer conexión MQTT"
          false
        end
      rescue => e
        Rails.logger.error "Error en publicación MQTT: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        raise e
      ensure
        disconnect(client) if client
      end
    end

    def subscribe(topic, &block)
      Rails.logger.info "Iniciando suscripción MQTT al tópico: #{topic}"
      
      begin
        client = connect
        client.subscribe(topic => 0)
        
        client.get do |t, message|
          Rails.logger.info "Mensaje recibido - Tópico: #{t}"
          Rails.logger.debug "Contenido: #{message}"
          yield(t, message) if block_given?
        end
      rescue => e
        Rails.logger.error "Error en suscripción MQTT: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        raise e
      ensure
        disconnect(client) if client
      end
    end

    def test_connection
      with_connection { |client| client.connected? }
    rescue => e
      Rails.logger.error "Error al probar conexión MQTT: #{e.message}"
      false
    end

    private

    def connect
      Rails.logger.info "Conectando a broker MQTT..."
      client = MQTT::Client.new(client_options)
      
      Timeout.timeout(TIMEOUT) do
        client.connect
        Rails.logger.info "Conexión MQTT establecida"
      end
      
      client
    rescue Timeout::Error
      Rails.logger.error "Timeout al conectar con broker MQTT"
      raise
    rescue => e
      Rails.logger.error "Error al conectar con broker MQTT: #{e.message}"
      raise
    end

    def disconnect(client)
      return unless client
      
      begin
        client.disconnect if client.connected?
        Rails.logger.info "Desconexión MQTT exitosa"
      rescue => e
        Rails.logger.error "Error al desconectar cliente MQTT: #{e.message}"
      end
    end

    def client_options
      {
        host: ENV.fetch('MQTT_HOST', DEFAULT_HOST),
        port: ENV.fetch('MQTT_PORT', DEFAULT_PORT).to_i,
        ssl: true,
        username: ENV['MQTT_USERNAME'],
        password: ENV['MQTT_PASSWORD'],
        client_id: "rails_client_#{Time.now.to_i}",
        keep_alive: 60,
        clean_session: true
      }
    end

    def with_connection
      client = MQTT::Client.new(client_options)
      
      begin
        client.connect
        yield client if block_given?
      ensure
        client&.disconnect if client&.connected?
      end
    end
  end
end
