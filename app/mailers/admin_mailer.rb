class AdminMailer < ApplicationMailer
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
