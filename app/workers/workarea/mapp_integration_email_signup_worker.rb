module Workarea
  #Worker for mapp integration includes when email signup is done on the DT site.
  class MappIntegrationEmailSignupWorker
    include Sidekiq::Worker
    include Sidekiq::CallbacksWorker

    sidekiq_options(
      retry: true,
      enqueue_on: { Workarea::Email::Signup => :create }
    )

    #Triggers the perform method depending on email signup create action.
    def perform(id)
      mapp_integration_flag = Rails.application.secrets.mapp_integration[:flag] rescue nil
      if mapp_integration_flag == true
        signup_data = Workarea::Email::Signup.find(id)
        #Hitting user_create and membership_subscribe_by_email api's by hitting 'mapp_integration_for_user_creation' method.
        Workarea::MappIntegration::MappIntegrationGateway.new.mapp_integration_for_user_creation(signup_data)
      end
    end
  end
end
