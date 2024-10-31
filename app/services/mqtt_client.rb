class MqttClient
    def self.publish(topic, payload)
      MQTT::Client.connect(
        host: ENV['MQTT_HOST'],
        port: ENV['MQTT_PORT'],
        username: ENV['MQTT_USERNAME'],
        password: ENV['MQTT_PASSWORD']
      ) do |client|
        client.publish(topic, payload, retain: false, qos: 1)
      end
    end
  end