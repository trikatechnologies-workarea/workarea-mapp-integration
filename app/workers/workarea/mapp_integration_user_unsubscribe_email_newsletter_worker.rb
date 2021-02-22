module Workarea
  #Worker for mapp integration includes when user do membership_unsubscribe_by_email for signup newsletter.
  class MappIntegrationUserUnsubscribeEmailNewsletterWorker
    include Sidekiq::Worker
    include Sidekiq::CallbacksWorker

    sidekiq_options(
      retry: true,
      enqueue_on: { Workarea::User => :update,
        only_if: -> { 
          # When checkbox for email_signup is unselected.
          Workarea::Email::Signup.find_by(email: self.email) rescue nil
        }
      }
    )

    #Triggers the perform method depending on the actions represented in enqueue_on
    def perform(id)
      mapp_integration_flag = Rails.application.secrets.mapp_integration[:flag] rescue nil
      if mapp_integration_flag == true
        user = Workarea::User.find(id)
        # calling membership_unsubscribe_by_email api
        Workarea::MappIntegration::MappIntegrationGateway.new.membership_unsubscribe_by_email(user)
      end
    end
  end
end
