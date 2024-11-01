require 'mqtt'

class MqttClient
  DEFAULT_HOST = 'b5b41cc0167e4c55bcc0f695f9b033ca.s1.eu.hivemq.cloud'
  DEFAULT_PORT = 8883
  TIMEOUT = 15
  RECONNECT_DELAY = 5

  class << self
    def publish(topic, payload)
      with_connection do |client|
        Rails.logger.info "Publicando mensaje en tópico: #{topic}"
        Rails.logger.info "Payload: #{payload}"
        
        client.publish(topic, payload, retain: false, qos: 0)
        
        Rails.logger.info "Mensaje publicado exitosamente en #{Time.current}"
      end
    end

    def test_connection
      with_connection { |client| client.connected? }
    rescue => e
      Rails.logger.error "Error al probar conexión MQTT: #{e.message}"
      false
    end

    def subscribe(topic)
      loop do
        begin
          client = MQTT::Client.new(client_options)
          client.connect
          
          Rails.logger.info "Suscribiendo a tópicos MQTT..."
          
          MqttService::TOPICS.values.each do |mqtt_topic|
            Rails.logger.info "Suscribiendo a: #{mqtt_topic}"
            client.subscribe(mqtt_topic => 0)
          end
          
          Rails.logger.info "Iniciando bucle de recepción de mensajes..."
          
          client.get do |t, message|
            Rails.logger.info "Mensaje recibido - Tópico: #{t}, Mensaje: #{message}"
            yield(t, message) if block_given?
          end
        rescue => e
          Rails.logger.error "Error en suscripción MQTT: #{e.message}. Reintentando en #{RECONNECT_DELAY} segundos..."
          client&.disconnect rescue nil
          sleep RECONNECT_DELAY
        end
      end
    end

    private

    def client_options
      {
        host: ENV['MQTT_HOST'] || DEFAULT_HOST,
        port: (ENV['MQTT_PORT'] || DEFAULT_PORT).to_i,
        ssl: true,
        username: ENV['MQTT_USERNAME'],
        password: ENV['MQTT_PASSWORD'],
        keep_alive: 120, # Aumentado para mantener la conexión más tiempo
        client_id: "rails_client_#{Time.now.to_i}" # ID único para cada cliente
      }
    end

    def with_connection
      client = MQTT::Client.new(client_options)
      
      begin
        Timeout.timeout(TIMEOUT) do
          client.connect
          yield client if block_given?
        end
      rescue Timeout::Error => e
        Rails.logger.error "Timeout en conexión MQTT: #{e.message}"
        raise
      rescue => e
        Rails.logger.error "Error en conexión MQTT: #{e.message}"
        raise
      ensure
        begin
          client.disconnect if client&.connected?
        rescue => e
          Rails.logger.error "Error al desconectar cliente MQTT: #{e.message}"
        end
      end
    end
  end
end