module Workarea
  #Worker for mapp integration includes updating the user api.
  class MappIntegrationUpdateUserWorker
    include Sidekiq::Worker
    include Sidekiq::CallbacksWorker

    sidekiq_options(
      retry: true,
      enqueue_on: { Workarea::User => :update }
    )

    #Triggers the perform method depending on the update action.
    def perform(id)
      mapp_integration_flag = Rails.application.secrets.mapp_integration[:flag] rescue nil
      if mapp_integration_flag == true
        update_user = Workarea::User.find(id)
        Workarea::MappIntegration::MappIntegrationGateway.new.mapp_integration_for_update_user(update_user)
      end
    end
  end
end
