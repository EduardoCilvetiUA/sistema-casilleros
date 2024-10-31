class ControllersController < ApplicationController
    before_action :authenticate_user!
    before_action :set_controller, only: [:edit, :update, :destroy]
  
    def index
      @controllers = current_user.controllers
      @new_controller = Controller.new
    end
  
    def create
      @controller = current_user.controllers.build(controller_params)
  
      respond_to do |format|
        if @controller.save
          format.html { 
            redirect_to controllers_path, 
            notice: 'Controlador creado exitosamente.' 
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
  
    def edit
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.update(
            "edit_controller_#{@controller.id}_form",
            partial: "controllers/form",
            locals: { controller: @controller }
          )
        }
      end
    end
  
    def update
      respond_to do |format|
        if @controller.update(controller_params)
          format.html { 
            redirect_to controllers_path, 
            notice: 'Controlador actualizado exitosamente.' 
          }
          format.turbo_stream {
            render turbo_stream: [
              turbo_stream.replace("controller_#{@controller.id}",
                partial: "controllers/controller",
                locals: { controller: @controller }
              ),
              turbo_stream.update("flash",
                partial: "shared/flash",
                locals: { notice: "Controlador actualizado exitosamente." }
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
          notice: 'Controlador eliminado exitosamente.' 
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
  
    private
  
    def set_controller
      @controller = current_user.controllers.find(params[:id])
    end
  
    def controller_params
      params.require(:controller).permit(:name, :location, :model_id)
    end
  end