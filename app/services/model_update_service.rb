class ModelUpdateService
    def self.initiate_update(controller, new_model)
      update = ModelUpdate.create!(
        controller: controller,
        model: new_model,
        status: :pending,
        started_at: Time.current
      )

      # Publicar mensaje MQTT para iniciar actualización
      MqttClient.publish(
        "Cambio_modelo",
        {
          controlador_id: controller.id,
          modelo_id: new_model.id,
          tamaño: new_model.size_bytes
        }.to_json
      )

      update
    end

    def self.update_status(controller_id, model_id, status)
      update = ModelUpdate.find_by!(
        controller_id: controller_id,
        model_id: model_id
      )

      update.update!(
        status: status,
        completed_at: (status == "completed" ? Time.current : nil)
      )

      # Notificar al administrador si la actualización falló
      AdminMailer.model_update_failed(update).deliver_later if status == "failed"
    end
end
