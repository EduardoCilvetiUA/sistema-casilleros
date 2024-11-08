require 'rails_helper'

RSpec.describe MqttService do
  let(:controller) { create(:controller) }
  let(:locker) { create(:locker, controller: controller) }
  let(:model) { create(:model) }
  let(:gestures) { create_list(:gesture, 4, model: model) }

  describe '.publish_locker_state' do
    it 'publishes locker state to MQTT broker' do
      expect(MqttClient).to receive(:publish).with(
        MqttService::TOPICS[:locker_state],
        {
          casillero_id: locker.id,
          estado: 0,
          fecha: anything,
          dueno: locker.owner_email,
          controlador_id: controller.id
        }.to_json
      )

      MqttService.publish_locker_state(locker)
    end
  end

  describe '.publish_owner_change' do
    it 'publishes owner change to MQTT broker' do
      new_owner = "new_owner@example.com"
      
      expect(MqttClient).to receive(:publish).with(
        MqttService::TOPICS[:owner_change],
        {
          casillero_id: locker.id,
          dueno_nuevo: new_owner,
          clave: gestures.map(&:id)
        }.to_json
      )

      MqttService.publish_owner_change(locker, new_owner, gestures)
    end
  end

  describe '.handle_mqtt_message' do
    it 'updates controller connection status' do
      payload = {
        "controlador_id" => controller.id,
        "estado" => 1
      }.to_json

      expect {
        MqttService.send(:handle_mqtt_message, MqttService::TOPICS[:connection], payload)
      }.to change { controller.reload.is_connected }.to(true)
    end
  end
end