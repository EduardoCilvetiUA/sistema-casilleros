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

  def user_model_params
    params.require(:user).permit(:active_model_id)
  end
end
