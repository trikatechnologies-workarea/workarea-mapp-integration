module Workarea
  #Worker for mapp integration includes Creating the user and membership_subscribe_by_email api's.
  class MappIntegrationCreateUserWorker
    include Sidekiq::Worker
    include Sidekiq::CallbacksWorker

    sidekiq_options(
      retry: true,
      enqueue_on: { Workarea::User => :create }
    )

    #Triggers the perform method depending on the actions represented in enqueue_on
    def perform(id)
      mapp_integration_flag = Rails.application.secrets.mapp_integration[:flag] rescue nil
      if mapp_integration_flag == true
        user = Workarea::User.find(id)
        Workarea::MappIntegration::MappIntegrationGateway.new.mapp_integration_for_user_creation(user)
      end
    end
  end
end
