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
      
      # Enviar email con la contraseña
      LockerMailer.password_updated(@locker).deliver_later
      
      redirect_to controller_lockers_path(@controller), notice: 'Casillero creado exitosamente'
    else
      redirect_to controller_lockers_path(@controller), alert: 'Error al crear el casillero'
    end
  end

  def update_password
    gesture_symbols = params[:gesture_sequence]

    if LockerPasswordService.update_password(@locker, gesture_symbols)
      render json: { 
        message: "Contraseña actualizada exitosamente",
        locker_id: @locker.id
      }
    else
      render json: { 
        error: "Error al actualizar la contraseña"
      }, status: :unprocessable_entity
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
