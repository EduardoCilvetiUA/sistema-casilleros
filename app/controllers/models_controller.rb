# app/controllers/models_controller.rb
class ModelsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_superuser, except: [:index, :show]

  def index
    @models = Model.all
    @new_model = Model.new if current_user&.is_superuser
  end

  def show
    @model = Model.find(params[:id])
  end

  def new
    @model = Model.new
  end

  def create
    @model = Model.new(model_params)
    if @model.save
      redirect_to models_path, notice: 'Modelo creado exitosamente.'
    else
      redirect_to models_path, alert: 'Error al crear el modelo.'
    end
  end

  def edit
    @model = Model.find(params[:id])
  end

  def update
    @model = Model.find(params[:id])
    if @model.update(model_params)
      redirect_to models_path, notice: 'Modelo actualizado exitosamente.'
    else
      render :edit
    end
  end

  private

  def check_superuser
    unless current_user&.is_superuser
      redirect_to models_path, alert: 'No tienes permiso para realizar esta acción.'
    end
  end

  def model_params
    params.require(:model).permit(:name, :active, :file_path, :size_bytes)
  end
end