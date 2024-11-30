class AdminMailer < ApplicationMailer
  def model_update_succeeded(model_update)
    @model_update = model_update
    @controller = model_update.controller
    @new_model = model_update.model
    @old_model = model_update.previous_model
    @admin = @controller.user

    mail(
      to: @admin.email,
      subject: "Actualización exitosa del modelo en el controlador #{@controller.name}"
    )
  end

    def model_update_failed(model_update)
      @model_update = model_update
      @controller = model_update.controller
      @admin = @controller.user

      mail(
        to: @admin.email,
        subject: "Falló la actualización del modelo en el controlador #{@controller.name}"
      )
    end
end
