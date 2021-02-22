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
      def membership_subscribe_by_email_api_query(user)
        {
          "email" => user.email,
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

      # Method triggers when creating the account
      def mapp_integration_for_user_creation(user)
        email_query = user_creation_api_query(user)
        email_body = user_creation_api_body(user)
        response = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/user/create", headers: headers, query: email_query, body: email_body)
        membership_subscribe_by_email(user)
      end

      # Method triggers when membership subscribe by email.
      def membership_subscribe_by_email(user)
        response = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/membership/subscribeByEmail", headers: headers, query: membership_subscribe_by_email_api_query(user) )
      end

      # Method triggers when user is updated.
      def mapp_integration_for_update_user(user)
        response = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/user/updateProfileByEmail", headers: headers, query: user_creation_api_query(user), body: update_user_api_email_body(user))
      end

      # Method triggers when membership unsubscribe by email.
      def membership_unsubscribe_by_email(user)
        response = HTTParty.post("#{Rails.application.secrets.mapp_integration[:api_endpoint]}"+"/membership/unsubscribeByEmail", headers: headers, query: membership_unsubscribe_by_email_api_query(user))
      end
    end
  end
end
