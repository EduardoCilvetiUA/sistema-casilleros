class LockersController < ApplicationController
  before_action :set_controller
  before_action :set_locker, only: [ :update_password, :password ]

  def index
    @lockers = @controller.lockers
    @new_locker = Locker.new(controller: @controller)
  end

  def create
    if @controller.lockers.count >= 4
      redirect_to controller_lockers_path(@controller), alert: "El controlador ya tiene el número máximo de casilleros (4)."
      return
    end

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

      # Registrar el evento de creación
      LockerEvent.create!(
        locker: @locker,
        event_type: "creation",
        success: true,
        event_time: Time.current
      )

      # Notificar al controlador físico y manejar el envío del correo
      if MqttService.publish_owner_change(@locker, @locker.owner_email, gestures)
        redirect_to controller_lockers_path(@controller), notice: "Casillero creado exitosamente"
        LockerMailer.owner_updated(@locker).deliver_later
      else
        redirect_to controller_lockers_path(@controller), alert: "Error al sincronizar el casillero"
      end
    else
      redirect_to controller_lockers_path(@controller), alert: "Error al crear el casillero, asegurate que el numero exista y que no este repetido"
    end
  end


  def update_password
    gesture_symbols = params[:gesture_sequence]

    # Convert gesture symbols to gesture names
    updated_gestures = gesture_symbols.map do |symbol|
      Gesture.find_by(symbol: symbol).name
    end

    # Notificar al controlador físico sobre el cambio de contraseña
    if MqttService.publish_password_change(@locker, updated_gestures)
      begin
        # Wait for confirmation from subscription_receiver with a timeout of 20 seconds
        Timeout.timeout(20) do
          MqttClient.subscribe([ MqttService::TOPICS[:subscription_receiver] ]) do |topic, message|
            Rails.logger.info "Mensaje recibido - Tópico: #{topic}"
            Rails.logger.info "Contenido: #{message}"

            begin
              # Ensure the message is properly encoded to UTF-8
              message.force_encoding("UTF-8")
              data = JSON.parse(message.gsub("“", '"').gsub("”", '"'))
              if data["casillero_id"] == @locker.id
                # Save the password in the database
                ActiveRecord::Base.transaction do
                  LockerPasswordService.update_password(@locker, gesture_symbols)

                  # Send email only here
                  LockerMailer.password_updated(@locker).deliver_later

                  LockerEvent.create!(
                    locker: @locker,
                    event_type: "password_update",
                    success: true,
                    event_time: Time.current
                  )
                end

                render json: { message: "Contraseña actualizada exitosamente" }
                return
              end
            rescue JSON::ParserError => e
              Rails.logger.error "Error parsing MQTT message: #{e.message}"
              render json: { error: "Error al procesar la respuesta del dispositivo" }, status: :unprocessable_entity
            rescue Encoding::CompatibilityError => e
              Rails.logger.error "Encoding error: #{e.message}"
              render json: { error: "Error de codificación al procesar la respuesta del dispositivo" }, status: :unprocessable_entity
            end
          end
        end
      rescue Timeout::Error
        Rails.logger.error "Timeout esperando confirmación de cambio de contraseña"
        render json: { error: "Timeout esperando confirmación de cambio de contraseña" }, status: :request_timeout
      end
    else
      render json: { error: "Error al sincronizar el cambio" }, status: :unprocessable_entity
    end
  end

  def update_owner
    @locker = @controller.lockers.find(params[:id])

    if @locker.update(owner_email: params[:owner_email])
      updated_gestures = @locker.locker_passwords.includes(:gesture)
                               .order(:position)
                               .map(&:gesture)

      if MqttService.publish_owner_change(@locker, @locker.owner_email, updated_gestures)
        # Send email only here
        LockerMailer.owner_updated(@locker).deliver_later

        LockerEvent.create!(
          locker: @locker,
          event_type: "owner_update",
          success: true,
          event_time: Time.current
        )
        puts "=== DEBUG OWNER ==="
        puts "Locker ID: #{params[:id]}"
        render json: { message: "Propietario actualizado exitosamente", locker_id: @locker.id }
      else
        render json: { error: "Error al sincronizar el cambio" }, status: :unprocessable_entity
      end
    else
      render json: { error: "Error al actualizar el propietario" }, status: :unprocessable_entity
    end
  end

  def password
    # Añadir logs detallados
    puts "=== DEBUG PASSWORD ==="
    puts "Locker ID: #{params[:id]}"
    puts "Controller ID: #{params[:controller_id]}"

    sequence = @locker.locker_passwords.includes(:gesture).order(:position).map { |lp| lp.gesture.symbol }
    puts "Sequence: #{sequence.inspect}"

    # Modificar la respuesta para incluir más información
    response = {
      password_sequence: sequence,
      locker_id: @locker.id,
      controller_id: @controller.id,
      timestamp: Time.current
    }

    puts "Sending response: #{response.inspect}"
    puts "===================="

    render json: response
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
