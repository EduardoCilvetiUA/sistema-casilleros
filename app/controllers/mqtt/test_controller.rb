# app/controllers/mqtt/test_controller.rb
class Mqtt::TestController < ApplicationController
  def index
    @controllers = Controller.all
    @lockers = Locker.all
    @topics = {
      locker_state: "Estado_Casillero",
      connection: "Conexion",
      owner_change: "Cambio_dueno",
      model_update_start: "actualizar_modelo/inicio",
      model_update_send: "actualizar_modelo/envio",
      model_update_receive: "actualizar_modelo/recepcion",
      model_update_install: "actualizar_modelo/instalacion"
    }

    @mqtt_status = {
      host: ENV["MQTT_HOST"] || MqttClient::DEFAULT_HOST,
      port: ENV["MQTT_PORT"] || MqttClient::DEFAULT_PORT,
      connected: false,
      error: nil
    }

    begin
      @mqtt_status[:connected] = MqttClient.test_connection
    rescue => e
      @mqtt_status[:error] = e.message
    end
  end

  def publish
    topic = params[:topic]
    payload = build_payload

    begin
      raise "Tópico no seleccionado" if topic.blank?
      raise "Payload inválido" if payload.nil?

      MqttClient.publish(topic, payload.to_json)
      flash[:notice] = "Mensaje MQTT publicado exitosamente"
    rescue => e
      flash[:alert] = "Error al publicar mensaje MQTT: #{e.message}"
    end
    Rails.logger.debug "Topic: #{topic}"
    Rails.logger.debug "Payload: #{payload.inspect}"
    redirect_to mqtt_test_path
  end

  private

  def build_payload
    case params[:topic]
    when "Estado_Casillero"
      {
        controller_id: params[:controller_id],
        locker_id: params[:locker_id],
        estado: params[:estado]
      }
    when "Cambio_dueno"
      {
        controller_id: params[:controller_id],
        locker_id: params[:locker_id],
        new_owner: params[:new_owner]
      }
    when "actualizar_modelo/envio"
      {
        gesture_ids: params[:gesture_ids].split(",").map(&:strip)
      }
    else
      # For custom or other topics, use custom_payload if provided
      return JSON.parse(params[:custom_payload]) if params[:custom_payload].present?
      nil
    end
  end
end
