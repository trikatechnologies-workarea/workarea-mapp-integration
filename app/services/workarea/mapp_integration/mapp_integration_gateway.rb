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

      # Membership subscribe API#
      def membership_subscribe_by_email(user)
        response = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/membership/subscribeByEmail", headers: headers, query: membership_subscribe_by_email_api_query(user.email) )
      end

      def membership_subscribe_by_email_api_query(email)
        {
          "email" => email,
          "groupId" => "#{Rails.application.secrets.mapp_integration[:group_id]}",
          "subscriptionMode" => "#{Rails.application.secrets.mapp_integration[:subscription_mode]}"
        }
      end

      # Membership Unsubscribe API#
      def membership_unsubscribe_by_email(user)
        response = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/membership/unsubscribeByEmail", headers: headers, query: membership_unsubscribe_by_email_api_query(user))
      end
 
      def membership_unsubscribe_by_email_api_query(user)
        {
          "email" => user.email,
          "groupId" => "#{Rails.application.secrets.mapp_integration[:group_id]}"
        }
      end

      # Account Creation API#
      def mapp_integration_for_user_creation(user) # Method triggers when creating the account in workarea
        response = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/user/create", headers: headers, query: user_creation_api_query(user), body: user_creation_api_body(user))
        if response.code != '200' || response.code != '204'
          resp = get_user_by_email_for_catalog(user)
          # membership_subscribe_by_email(user)
          user_creation_transaction_api(resp)
        else
          # membership_subscribe_by_email(user)
          user_creation_transaction_api(response)
        end
      end

      def user_creation_api_query(user) # This method greps the user and assaigns the value to email.
        {
          "email" => user.email,
          "messageId" => "#{Rails.application.secrets.mapp_integration[:user_create_api_message_id]}"
        }
      end
      
      def user_creation_api_body(user) # This method greps the user and assaigns the values and especially written for api body.
        [
          {
          "name" => 'email',
          "value" => user.email
          }
        ].to_json
      end

      def user_creation_transaction_api(response)
        transaction = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/message/sendTransactional", headers: headers, query: user_creation_transaction_api_query(response), body: mapp_email_signup_transaction_api_body(response))
      end

      def user_creation_transaction_api_query(response)
        {
          "recipientId" => response.parsed_response["id"],
          "messageId" => "#{Rails.application.secrets.mapp_integration[:user_create_api_message_id]}",
          "externalTransactionFormula" => "null"
        }
      end

      # Email signup API#
      def mapp_integration_email_signup_api(signup_data)
        response = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/user/create", headers: headers, query: mapp_email_signup_api_query(signup_data), body: mapp_email_signup_api_body(signup_data))
        membership_subscribe_by_email(signup_data)
        # mapp_email_signup_transaction_api(response)
      end

      def mapp_email_signup_api_query(signup_data)
        {
          "email" => signup_data.email
        }
      end

      def mapp_email_signup_api_body(signup_data)
        [
          {
          "name" => 'email',
          "value" => signup_data.email
          }
        ].to_json
      end

      def mapp_email_signup_transaction_api(response)
        HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/message/sendTransactional", headers: headers, query: mapp_email_signup_transaction_api_query(response), body: mapp_email_signup_transaction_api_body(response))
      end

      def mapp_email_signup_transaction_api_query(response)
        {
          "recipientId" => response.parsed_response["id"],
          "messageId" => "#{Rails.application.secrets.mapp_integration[:email_signup_api_message_id]}",
          "externalTransactionFormula" => "null"
        }
      end

      def mapp_email_signup_transaction_api_body(response)
        {
        "parameters" =>
          [
            {"name" => "Parameter Name 1","value" => "Parameter Value 1"},
            {"name" => "Parameter Name 2","value" => "Parameter Value 2"}
          ]
        }.to_json
      end
      # Update User API#
      def mapp_integration_for_update_user(user) # Method triggers when user is updated in workarea
        response = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/user/updateProfileByEmail", headers: headers, query: update_user_creation_api_query(user), body: update_user_creation_api_body(user))
      end

      def update_user_creation_api_query(user)
        {
          "email" => user.email
        }
      end
      
      def update_user_creation_api_body(user) # Request body for update_user api
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

      # Catalog Form API#
      def mapp_email_signup_from_catalog_form(user)
        response = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/user/create", headers: headers, query: catalog_form_user_creation_api_query(user), body: catalog_form_user_creation_api_body(user))
        if response.code != '200' || response.code != '204'
          resp = get_user_by_email_for_catalog(user)
          # membership_subscribe_by_email(user)
          catalog_form_transaction_api(resp)
        else
          # membership_subscribe_by_email(user)
          catalog_form_transaction_api(response)
        end

        if user.signup_email
          membership_subscribe_by_email(user)
        end
      end
      
      # Welcome API#
      def mapp_welcome_email_signup(user)
        response = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/user/create", headers: headers, query: catalog_form_user_creation_api_query(user), body: catalog_form_user_creation_api_body(user))
        if response.code != '200' || response.code != '204'
          resp = get_user_by_email_for_catalog(user)
          membership_subscribe_by_email(user)
          welcome_form_transaction_api(resp)
        else
          membership_subscribe_by_email(user)
          welcome_form_transaction_api(response)
        end
      end
      

      def catalog_form_user_creation_api_query(user)
        {
          "email" => user.email,
          "messageId" => "#{Rails.application.secrets.mapp_integration[:catalog_request_api_message_id]}"
        }
      end

      def catalog_form_user_creation_api_body(user)
        [
          {
          "name" => 'email',
          "value" => user.email
          }
        ].to_json
      end

      def catalog_form_transaction_api(response)
        response = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/message/sendTransactional", headers: headers, query: catalog_form_transaction_api_query(response), body: mapp_email_signup_transaction_api_body(response))
      end

      def welcome_form_transaction_api(response)
        response = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/message/sendTransactional", headers: headers, query: welcome_form_transaction_api_query(response), body: mapp_email_signup_transaction_api_body(response))
      end

      def catalog_form_transaction_api_query(response)
        {
          "recipientId" => response.parsed_response["id"],
          "messageId" => "#{Rails.application.secrets.mapp_integration[:catalog_request_api_message_id]}",
          "externalTransactionFormula" => "null"
        }
      end

      def welcome_form_transaction_api_query(response)
        {
          "recipientId" => response.parsed_response["id"],
          "messageId" => "#{Rails.application.secrets.mapp_integration[:email_signup_api_message_id]}",
          "externalTransactionFormula" => "null"
        }
      end

      # Order placed API #
      # Hitting order placed api when we place order in workarea.
      def mapp_integration_for_order_placed(order, user_id)
        response = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/message/sendTransactionalWithEventDetails", headers: headers, query: order_placed_api_query(order, user_id), body: order_placed_api_body(order, user_id))
      end

      def order_placed_api_query(order, user_id)
        {
          "recipientId" => "#{user_id}",
          "messageId" => "#{Rails.application.secrets.mapp_integration[:order_placed_api_message_id]}",
          "externalTransactionFormula" => "#{order.id}"
        }
      end

      def order_placed_api_body(order, user_id) # Calling the sendTransactionalWithEventDetails api body from order.decorator in the DT project
        order.mapp_order_placed_api_body(order, user_id)
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

      def user_get_by_email_query(email)
        {
          "email" => email
        }
      end

      # Creating the account in mapp for guest user in workarea. 
      def user_creation_for_guest_user(user)
        response = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/user/create", headers: headers, query: user_creation_api_query(user), body: user_creation_api_body(user))
      end

      # Subscribe by Email API when subscribing from billing address#
      def membership_subscribe_from_billing_address(email)
        HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/membership/subscribeByEmail", headers: headers, query: membership_subscribe_by_email_api_query(email) )
      end

      def subscribe_from_billing_address_transaction(email)
        response = HTTParty.get("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/user/getByEmail", headers: headers, query: user_get_by_email_query(email))
        mapp_email_signup_transaction_api(response)
      end

      def get_user_by_email_for_catalog(user)
        response = HTTParty.get("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/user/getByEmail", headers: headers, query: user_get_by_email_query(user.email))
      end
    end
  end
end
