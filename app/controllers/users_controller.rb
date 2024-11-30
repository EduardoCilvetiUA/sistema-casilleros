# app/controllers/users_controller.rb
class UsersController < ApplicationController
  before_action :authenticate_user!

  def update_model
    @user = User.find(params[:id])
    old_model_id = @user.active_model_id

    ActiveRecord::Base.transaction do
      if @user.update(user_model_params)
        # Update all user's controllers to use the new model
        new_model = Model.find(@user.active_model_id)
        old_model = old_model_id ? Model.find_by(id: old_model_id) : nil

        @user.controllers.each do |controller|
          # Create model update record
          model_update = ModelUpdate.create!(
            controller: controller,
            model: new_model,
            previous_model: old_model,
            status: :succeeded
          )

          # Update controller's model
          controller.update!(model_id: @user.active_model_id)

          # Enviar mensaje MQTT
          MqttService.publish_model_change(controller, old_model, new_model)

          # Actualizar las contraseñas de los casilleros
          update_locker_passwords(controller, new_model)

          # Send email notification
          AdminMailer.model_update_succeeded(model_update).deliver_later
        end

        redirect_to controllers_path, notice: "Modelo actualizado exitosamente"
      else
        raise ActiveRecord::Rollback
        redirect_to controllers_path, alert: "Error al actualizar el modelo"
      end
    end
  rescue => e
    Rails.logger.error "Error updating user model: #{e.message}"
    redirect_to controllers_path, alert: "Error al actualizar el modelo"
  end

  private

  def update_locker_passwords(controller, new_model)
    # Obtener todos los casilleros asociados al controlador
    controller.lockers.each do |locker|
      # Seleccionar 4 gestos al azar del nuevo modelo
      new_gestures = new_model.gestures.sample(4)
      
      # Limpiar contraseñas existentes
      locker.locker_passwords.destroy_all
      
      # Asignar nuevos gestos
      locker_passwords = []
      new_gestures.each_with_index do |gesture, index|
        locker_passwords << LockerPassword.create!(
          locker: locker,
          gesture: gesture,
          position: index # Las posiciones empiezan desde 0
        )
      end
  
      # Preparar los gestos desde la base de datos para garantizar consistencia
      saved_passwords = locker.locker_passwords.order(:position)
      gesture_symbols = saved_passwords.map { |lp| lp.gesture.symbol }
  
      # Enviar mensaje MQTT con los gestos asignados
      MqttService.publish_password_change(locker, gesture_symbols)
    
      # Enviar correo con los mismos gestos asignados
      LockerMailer.password_updated(locker).deliver_later
    end
  end
  

  def user_model_params
    params.require(:user).permit(:active_model_id)
  end
end
