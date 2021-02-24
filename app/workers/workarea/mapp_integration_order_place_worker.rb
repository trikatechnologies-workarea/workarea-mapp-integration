module Workarea
  #Worker for mapp integration includes hitting the order placed api.
  class MappIntegrationOrderPlaceWorker
    include Sidekiq::Worker
    include Sidekiq::CallbacksWorker

    sidekiq_options(
      retry: true,
      enqueue_on: { Workarea::Order => :place }
    )

    #Triggers the perform method depending on the order place action.
    def perform(id)
      mapp_integration_flag = Rails.application.secrets.mapp_integration[:flag] rescue nil
      if mapp_integration_flag == true
        order = Workarea::Order.find(id)
        Workarea::MappIntegration::MappIntegrationGateway.new.get_user_by_email(order)
      end
    end
  end
end
