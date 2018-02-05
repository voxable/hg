# frozen_string_literal: true

# TODO: Test & Document
module Hg
  module Dialogflow
    class Client
      class QueryError < StandardError
        def initialize
          super('There was a problem with the Dialogflow query.')
        end
      end

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

      # Parse a natural language message with Dialogflow.
      #
      # @param message [String]
      #   The natural language query to be parsed.
      # @param context_name [String]
      #   The context name to set on the Dialogflow session.
      #
      # @return [Hash] The information parsed from the message.
      def query(message, context_name: nil)
        # TODO: which logger?
        retry_counter = 0

        begin
          retry_counter += 1

          # Build a contexts object if one is passed.
          contexts = context_name ? [context_name] : nil

          api_ai_response = @client.text_request(message, contexts: contexts)
        rescue ApiAiRuby::ClientError, ApiAiRuby::RequestError => e
          Sidekiq::Logging.logger.error 'Error with Dialogflow query request'
          Sidekiq::Logging.logger.error e
          Sidekiq::Logging.logger.error e.backtrace.join("\n")

          # Retry the call 3 times.
          retry if retry_counter < 3

          raise QueryError.new
        else
          # If the Dialogflow call fails...
          if api_ai_response[:status][:code] != 200
            # ...log an error.
            Sidekiq::Logging.logger.error "Error with Dialogflow request: #{api_ai_response.inspect}"

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
          action_name =
            if action_from_response.blank?
              intent_name
            # Set to default action if message is not recognized.
            elsif action_from_response == UNKNOWN_SYSTEM_ACTION.freeze
              Hg::InternalActions::DEFAULT
            else
              action_from_response
            end

          fulfillment = api_ai_response[:result][:fulfillment]

          return {
            intent: intent_name,
            action: action_name,
            parameters: parsed_params(api_ai_response[:result][:parameters]),
            fulfillment: fulfillment
          }
        end
      end

      private

      # Remove any params which were not matched.
      #
      # @param params [Hash]
      #   The raw parsed params.
      #
      # @return [Hash]
      #   Only those params that were matched.
      def parsed_params(params)
        params.reject{ |p| p.blank? }
      end
    end
  end
end
