# app/controllers/controllers_controller.rb
class ControllersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_controller, only: [ :update, :destroy, :sync ] # Removemos :edit

  def index
    @controllers =Controller.all
    @new_controller = Controller.new
  end

  def create
    @controller = current_user.controllers.build(controller_params)

    respond_to do |format|
      if @controller.save
        format.html {
          redirect_to controllers_path,
          notice: "Controlador creado exitosamente."
        }
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.prepend("controllers",
              partial: "controllers/controller",
              locals: { controller: @controller }
            ),
            turbo_stream.update("flash",
              partial: "shared/flash",
              locals: { notice: "Controlador creado exitosamente." }
            )
          ]
        }
      else
        format.html {
          redirect_to controllers_path,
          alert: @controller.errors.full_messages.to_sentence
        }
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.update("new_controller_form",
              partial: "controllers/form",
              locals: { controller: @controller }
            ),
            turbo_stream.update("flash",
              partial: "shared/flash",
              locals: { alert: @controller.errors.full_messages.to_sentence }
            )
          ]
        }
      end
    end
  end

  def update
    respond_to do |format|
      original_model_id = @controller.model_id

      if @controller.update(controller_params)
        if @controller.saved_change_to_model_id?
          new_model = Model.find(@controller.model_id)
          old_model = Model.find(original_model_id)

          # Crear el registro de actualización
          model_update = ModelUpdate.create!(
            controller: @controller,
            model: new_model,
            previous_model: old_model,
            status: :succeeded
          )

          # Enviar mensaje MQTT
          MqttService.publish_model_change(@controller, old_model, new_model)

          # Enviar el email con el model_update
          AdminMailer.model_update_succeeded(model_update).deliver_later

          flash[:notice] = "Controlador actualizado exitosamente. Modelo cambiado de #{old_model.name} a #{new_model.name}"
        else
          flash[:notice] = "Controlador actualizado exitosamente."
        end

        format.html { redirect_to controllers_path }
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.replace("controller_#{@controller.id}",
              partial: "controllers/controller",
              locals: { controller: @controller }
            ),
            turbo_stream.update("flash",
              partial: "shared/flash",
              locals: { notice: flash[:notice] }
            )
          ]
        }
      else
        format.html {
          redirect_to controllers_path,
          alert: @controller.errors.full_messages.to_sentence
        }
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.update("edit_controller_#{@controller.id}_form",
              partial: "controllers/form",
              locals: { controller: @controller }
            ),
            turbo_stream.update("flash",
              partial: "shared/flash",
              locals: { alert: @controller.errors.full_messages.to_sentence }
            )
          ]
        }
      end
    end
  end

  def destroy
    @controller.destroy

    respond_to do |format|
      format.html {
        redirect_to controllers_path,
        notice: "Controlador eliminado exitosamente."
      }
      format.turbo_stream {
        render turbo_stream: [
          turbo_stream.remove("controller_#{@controller.id}"),
          turbo_stream.update("flash",
            partial: "shared/flash",
            locals: { notice: "Controlador eliminado exitosamente." }
          )
        ]
      }
    end
  end

  def sync
    respond_to do |format|
      begin
        Rails.logger.info "Iniciando sincronización para controlador #{@controller.id}"

        if MqttService.publish_sync_request(@controller)
          flash[:notice] = "Iniciando sincronización del controlador..."
        else
          flash[:alert] = "Error al iniciar la sincronización"
        end

        format.html { redirect_to controllers_path }
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.replace(
              "controller_#{@controller.id}",
              partial: "controllers/controller",
              locals: { controller: @controller }
            ),
            turbo_stream.update(
              "flash",
              partial: "shared/flash",
              locals: { notice: flash[:notice], alert: flash[:alert] }
            )
          ]
        }
      rescue => e
        Rails.logger.error "Error en sincronización: #{e.message}"
        flash[:alert] = "Error al sincronizar: #{e.message}"
        format.html { redirect_to controllers_path }
        format.turbo_stream {
          render turbo_stream: turbo_stream.update(
            "flash",
            partial: "shared/flash",
            locals: { alert: flash[:alert] }
          )
        }
      end
    end
  end

  private

  def set_controller
    if current_user.superuser?
      @controller = Controller.find(params[:id])
    else
      @controller = current_user.controllers.find(params[:id])
    end
  end

  def controller_params
    params.require(:controller_model).permit(:name, :location, :model_id)
  end
end
