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
        # For making 'sendTransactionalWithEventDetails' api, we are first hitting get_user_by email api.
        # Workarea::MappIntegration::MappIntegrationGateway.new.get_user_by_email(order)
        # While doing checkout process, when user selects the sign-me-up checkbox from billing address, we are hitting "membership subscribe by email" api. 
        order_view_model = Workarea::Storefront::OrderViewModel.new(order)
        checkbox = order_view_model.billing_address.signup_checkbox

        if checkbox == true
          Workarea::MappIntegration::MappIntegrationGateway.new.membership_subscribe_from_billing_address(order.email)
          Workarea::MappIntegration::MappIntegrationGateway.new.subscribe_from_billing_address_transaction(order.email)
        end
      end
    end
  end
end
