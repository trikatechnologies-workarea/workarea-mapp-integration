require 'net/http'
require 'httparty'

module Workarea
  module MappIntegration
    # Sending the data to MAPP via Api upon several actions on design toscano site.
    class MappIntegrationGateway
      # Converting username and password to ruby basic auth.
      def basic_auth
        auth = "Basic " + Base64::encode64("#{Rails.application.secrets.mapp_integration[:username]}:#{Rails.application.secrets.mapp_integration[:password]}")
      end

      # Generating headers for succesfull api.
      def headers
        {
          "Authorization" => basic_auth,
          "Content-Type" => "application/json",
          "Accept" => "application/json"
        }
      end

      # This method greps the user and assaigns the value to email.
      def user_creation_api_query(user)
        {
          "email" => user.email
        }
      end

      # This method greps the user and assaigns the values and especially written for api body.
      def user_creation_api_body(user)
        [
          {
          "name" => 'email',
          "value" => user.email
          }
        ].to_json
      end

      # Request body for update_user api
      def update_user_api_email_body(user)
        [
          {
            "name" => "email",
            "value" => user.email
          },
          {
            "name" =>"email",
            "value" => user.email
          }
        ].to_json
      end

      # query for membership_subscribe_by_email
      def membership_subscribe_by_email_api_query(email)
        {
          "email" => email,
          "groupId" => "#{Rails.application.secrets.mapp_integration[:group_id]}",
          "subscriptionMode" => "#{Rails.application.secrets.mapp_integration[:subscription_mode]}"
        }
      end

      # Query for membership_unsubscribe_by_email_api_query
      def membership_unsubscribe_by_email_api_query(user)
        {
          "email" => user.email,
          "groupId" => "#{Rails.application.secrets.mapp_integration[:group_id]}"
        }
      end

      # Query for get_user_by_email_api.
      def user_get_by_email_query(email)
        {
          "email" => email
        }
      end

      # Query for order placed api.
      def order_placed_api_query(order, user_id)
        {
          "recipientId" => "#{user_id}",
          "messageId" => "#{Rails.application.secrets.mapp_integration[:message_id]}",
          "externalTransactionFormula" => "#{order.id}"
        }
      end

      # Calling the sendTransactionalWithEventDetails api body from order.decorator in the DT project
      def order_placed_api_body(order, user_id)
        order.mapp_order_placed_api_body(order, user_id)
      end

      # Method triggers when creating the account
      def mapp_integration_for_user_creation(user)
        response = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/user/create", headers: headers, query: user_creation_api_query(user), body: user_creation_api_body(user))
        membership_subscribe_by_email(user)
      end

      # Method triggers when membership subscribe by email.
      def membership_subscribe_by_email(user)
        response = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/membership/subscribeByEmail", headers: headers, query: membership_subscribe_by_email_api_query(user.email) )
      end

      # Method triggers when user is updated.
      def mapp_integration_for_update_user(user)
        response = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/user/updateProfileByEmail", headers: headers, query: user_creation_api_query(user), body: update_user_api_email_body(user))
      end

      # Method triggers when membership unsubscribe by email.
      def membership_unsubscribe_by_email(user)
        response = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/membership/unsubscribeByEmail", headers: headers, query: membership_unsubscribe_by_email_api_query(user))
      end

      # Creating the account in mapp for guest user in workarea. 
      def user_creation_for_guest_user(user)
        response = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/user/create", headers: headers, query: user_creation_api_query(user), body: user_creation_api_body(user))
      end
      
      # Hitting order placed api when we place order in workarea.
      def mapp_integration_for_order_placed(order, user_id)
        response = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/message/sendTransactionalWithEventDetails", headers: headers, query: order_placed_api_query(order, user_id), body: order_placed_api_body(order, user_id))
      end

      # Hitting user get by email api to verify the user existance. If yes, we are calling the sendTransactionalWithEventDetails api.
      # If user is not present(i.e., guest user in workarea) in mapp, we are calling user_creation api and from there fetching the mappuser_id. 
      def get_user_by_email(order)
        response = HTTParty.get("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/user/getByEmail", headers: headers, query: user_get_by_email_query(order.email))
        user_id_from_response = response.parsed_response["id"]

        begin
          if user_id_from_response.nil?
            guest_user_response = Workarea::MappIntegration::MappIntegrationGateway.new.user_creation_for_guest_user(order)
            user_id = guest_user_response.parsed_response["id"]
            Workarea::MappIntegration::MappIntegrationGateway.new.mapp_integration_for_order_placed(order, user_id)
          else
            Workarea::MappIntegration::MappIntegrationGateway.new.mapp_integration_for_order_placed(order, user_id_from_response)
          end
        rescue Timeout::Error => e
          Rails.logger.info "Rescued #{e.message}"
        end
      end

      def membership_subscribe_from_billing_address(email)
        response = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/membership/subscribeByEmail", headers: headers, query: membership_subscribe_by_email_api_query(email) )
      end
    end
  end
end
