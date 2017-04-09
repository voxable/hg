# frozen_string_literal: true

# TODO: Test & Document
module Hg
  class ApiAiClient
    # Name of action for unrecognized messages.
    UNKNOWN_SYSTEM_ACTION = 'input.unknown'

    def initialize(session_id)
      # TODO: access token should be set by Hg config option
      @client = ApiAiRuby::Client.new(
        client_access_token: ENV['API_AI_CLIENT_ACCESS_TOKEN'],
        api_version: '20170210',
        api_session_id: session_id
      )
    end

    def query(message)
      # TODO: which logger?
      begin
        api_ai_response = @client.text_request(message)
      rescue StandardError => e
        Sidekiq::Logging.logger.error 'Error with API.ai request'
        Sidekiq::Logging.logger.error e
        Sidekiq::Logging.logger.error e.backtrace.join("\n")
      end

      # If the API.ai call fails...
      if api_ai_response[:status][:code] != 200
        # ...log an error.
        Sidekiq::Logging.logger.error "Error with API.ai request: #{api_ai_response.inspect}"

        # Return the default action.
        return {
          action: Hg::InternalActions::DEFAULT,
          intent: Hg::InternalActions::DEFAULT
        }
      end

      intent_name = api_ai_response[:result][:metadata][:intentName]

      # Determine the action name
      action_from_response = api_ai_response[:result][:action]
                    # Use intent name as action name if no action name is defined for this intent.
      action_name = if action_from_response.blank?
                      intent_name
                    # Set to default action if message is not recognized.
                    elsif action_from_response == UNKNOWN_SYSTEM_ACTION.freeze
                      Hg::InternalActions::DEFAULT
                    else
                      action_from_response
                    end

      response = api_ai_response[:result][:fulfillment][:speech]

      return {
        intent: intent_name,
        action: action_name,
        parameters: api_ai_response[:result][:parameters],
        response: response
      }
    end
  end
end
