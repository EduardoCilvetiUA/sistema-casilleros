# app/controllers/controllers_controller.rb
class ControllersController < ApplicationController
  before_action :authenticate_user!

  def index
    @controllers = Controller.all
    @new_controller = Controller.new  # Añade esta línea
  end

  def create
    @controller = current_user.controllers.build(controller_params)
    
    if @controller.save
      redirect_to controllers_path, notice: 'Controlador creado exitosamente'
    else
      redirect_to controllers_path, alert: 'Error al crear el controlador'
    end
  end

  def update
    @controller = Controller.find(params[:id])
    if @controller.update(controller_params)
      redirect_to controllers_path, notice: 'Controlador actualizado exitosamente'
    else
      redirect_to controllers_path, alert: 'Error al actualizar el controlador'
    end
  end

  private

  def controller_params
    params.require(:controller).permit(:name, :location, :model_id)
  end
end