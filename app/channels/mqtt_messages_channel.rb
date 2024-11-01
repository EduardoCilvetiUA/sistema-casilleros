class MqttMessagesChannel < ApplicationCable::Channel
  def subscribed
    stream_from "mqtt_messages_channel"
  end

  def unsubscribed
  end
end
