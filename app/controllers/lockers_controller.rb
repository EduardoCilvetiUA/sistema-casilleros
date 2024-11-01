class LockersController < ApplicationController
  before_action :set_controller
  before_action :set_locker, only: [:update_password]

  def index
    @lockers = @controller.lockers
    @new_locker = Locker.new(controller: @controller)
  end

  def create
    @locker = @controller.lockers.build(locker_params)
    
    if @locker.save
      # Crear contraseña inicial aleatoria
      gestures = @controller.model.gestures.sample(4)
      gestures.each_with_index do |gesture, position|
        @locker.locker_passwords.create!(
          gesture: gesture,
          position: position
        )
      end
      
      # Notificar al controlador físico sobre el nuevo casillero y su contraseña
      MqttService.publish_owner_change(@locker, @locker.owner_email, gestures)
      
      # Enviar email con la contraseña
      LockerMailer.password_updated(@locker).deliver_later
      
      # Registrar el evento de creación
      LockerEvent.create!(
        locker: @locker,
        event_type: 'creation',
        success: true,
        event_time: Time.current
      )
      
      redirect_to controller_lockers_path(@controller), notice: 'Casillero creado exitosamente'
    else
      redirect_to controller_lockers_path(@controller), alert: 'Error al crear el casillero'
    end
  end

  def update_password
    gesture_symbols = params[:gesture_sequence]

    ActiveRecord::Base.transaction do
      if LockerPasswordService.update_password(@locker, gesture_symbols)
        # Obtener los gestos actualizados para enviar al MQTT
        updated_gestures = @locker.locker_passwords.includes(:gesture)
                                 .order(:position)
                                 .map(&:gesture)

        # Notificar al controlador físico sobre el cambio de contraseña
        MqttService.publish_owner_change(@locker, @locker.owner_email, updated_gestures)
        
        # Registrar el evento de actualización
        LockerEvent.create!(
          locker: @locker,
          event_type: 'password_update',
          success: true,
          event_time: Time.current
        )

        render json: { 
          message: "Contraseña actualizada exitosamente",
          locker_id: @locker.id
        }
      else
        # Registrar el evento fallido
        LockerEvent.create!(
          locker: @locker,
          event_type: 'password_update',
          success: false,
          event_time: Time.current
        )

        render json: { 
          error: "Error al actualizar la contraseña"
        }, status: :unprocessable_entity
      end
    end
  end

  private

  def set_controller
    @controller = Controller.find(params[:controller_id])
  end

  def set_locker
    @locker = @controller.lockers.find(params[:id])
  end

  def locker_params
    params.require(:locker).permit(:number, :owner_email)
  end
end