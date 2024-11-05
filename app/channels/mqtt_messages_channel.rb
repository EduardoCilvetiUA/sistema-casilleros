# app/channels/mqtt_messages_channel.rb
class MqttMessagesChannel < ApplicationCable::Channel
  VALID_TOPICS = MqttService::TOPICS.values.freeze

  def subscribed
    stream_from "mqtt_messages_channel"
  end

  def received(data)
    return unless VALID_TOPICS.include?(data['topic'])
    
    # Procesar solo mensajes válidos
    transmit(
      topic: data['topic'],
      message: data['message'],
      timestamp: Time.current.iso8601
    )
  end

  def unsubscribed
    # Cleanup de recursos si es necesario
  end

  private

  def valid_message?(data)
    data.is_a?(Hash) && 
      data['topic'].present? && 
      data['message'].present? &&
      VALID_TOPICS.include?(data['topic'])
  end
end