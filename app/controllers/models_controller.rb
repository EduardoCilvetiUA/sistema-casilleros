# app/controllers/models_controller.rb
class ModelsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_superuser, except: [ :index, :show ]

  def index
    @models = Model.all
    @new_model = Model.new if current_user&.is_superuser
    6.times { @new_model.gestures.build } if current_user&.is_superuser
  end

  def show
    @model = Model.find(params[:id])
  end

  def new
    @model = Model.new
    6.times { @new_model.gestures.build } if current_user&.is_superuser
  end

  def create
    puts "\n==== PARÁMETROS RECIBIDOS ===="
    puts "Todos los parámetros:"
    puts params.inspect
    puts "\nParámetros del modelo:"
    puts params[:model].inspect
    puts "\nParámetros de gestos:"
    puts params[:model][:gestures_attributes].inspect if params[:model][:gestures_attributes].present?
    puts "===========================\n"

    params[:model][:active] = ActiveModel::Type::Boolean.new.cast(params[:model][:active])

    puts "\nACTIVE2: #{params[:model][:active]}"

    @model = Model.new(model_params)

    if @model.save
      gesture_params = params[:model][:gestures_attributes]
      puts "\n==== GESTURE PARAMS ===="
      puts gesture_params.inspect
      puts "======================="
      redirect_to models_path, notice: "Modelo creado exitosamente."
    else
      redirect_to models_path, alert: "Error al crear el modelo."
    end
  end

  def edit
    @model = Model.find(params[:id])
    # Asegurarse de que haya exactamente 6 gestos
    remaining_gestures = 6 - @model.gestures.count
    remaining_gestures.times { @model.gestures.build } if remaining_gestures > 0
  end

  def update
    @model = Model.find(params[:id])
    if @model.update(model_params)
      # Crear nuevos gestos
      redirect_to models_path, notice: "Modelo actualizado exitosamente."
    else
      render :edit
    end
  end

  def gestos
    @model = Model.find(params[:id])
    @gestures = @model.gestures
    response = {
      gestures: @gestures.map { |gesture|
        {
          name: gesture.name,
          symbol: gesture.symbol
        }
      }
    }
    render json: response
  end

  def destroy
    @model = Model.find(params[:id])
    begin
      ActiveRecord::Base.transaction do
        if @model.gestures.joins(:locker_passwords).any?
          raise ActiveRecord::RecordNotDestroyed, "No se puede eliminar un modelo que está asignado a un casillero"
        end

        # Primero eliminamos los gestos
        @model.gestures.destroy_all

        # Luego eliminamos el modelo
        if @model.destroy
          redirect_to models_path, notice: "Modelo eliminado exitosamente."
        else
          raise ActiveRecord::RecordNotDestroyed, "Error al eliminar el modelo"
        end
      end
    rescue ActiveRecord::RecordNotDestroyed => e
      redirect_to models_path, alert: e.message
    rescue ActiveRecord::InvalidForeignKey
      redirect_to models_path, alert: "No se puede eliminar un modelo que está asignado a un casillero"
    end
  end

  private

  def check_superuser
    unless current_user&.is_superuser
      redirect_to models_path, alert: "No tienes permiso para realizar esta acción."
    end
  end

  def model_params
    params.require(:model).permit(
    :name,
    :active,
    :file_path,
    :size_bytes,
    gestures_attributes: [ :id, :name, :symbol, :_destroy ]
  )
  end
end
