# frozen_string_literal: true

module Hg
  module Workers
    class Base
      include Sidekiq::Worker

      private

      # Pop a message from the passed queue.
      #
      # @param queue_class [Class] The class representing the queue from which
      #   to pop
      # @param user_id [String, Integer] The ID representing the user on this platform
      # @param namespace [String] The redis namespace under which the message to
      #   process is nested.
      #
      # @return [Hash] The raw, popped message.
      def pop_from_queue(queue_class, user_id:, namespace:)
        queue_class
          .new(user_id: user_id, namespace: namespace)
          .pop
      end

      # Find the appropriate user for this request.
      #
      # @param bot [Class] The class representing the bot in question.
      # @param user_id [String, Integer] The id of the user to fetch.
      #
      # @return [Object] The user that initiated the request.
      def find_bot_user(bot, user_id)
        bot.user_class.find_or_create_by(facebook_psid: user_id)
      end

      # Parse a message via an NLU service (at the moment, API.ai).
      #
      # @param text [String]
      #   The raw text of the message.
      # @param user [API]
      #   The user that sent the message.
      #
      # @return [Array<Hash>]
      #   An array in which the first element is the raw NLU response, and the
      #   second element is the parsed parameters.
      def parse_message(text, user)
        begin
          # ...send the message to API.ai for NLU.
          nlu_response = ApiAiClient.new(user.api_ai_session_id)
                           .query(text, context_name: user.dialogflow_context_name)

          # Clear the Dialogflow context.
          user.update_attributes(dialogflow_context_name: nil) if user.dialogflow_context_name
        rescue Hg::ApiAiClient::QueryError => e
          log_error(e)
        else
          # Drop any params that weren't recognized.
          params = nlu_response[:parameters].reject {|k, v| v.blank?}
        end

        return nlu_response, params
      end

      # Build a request object from a payload and user.
      #
      # @param payload [Facebook::Messenger::Incoming] The postback payload.
      # @param user [Object] The user that sent the payload.
      #
      # @return [Hg::Request] The generated request.
      def build_payload_request(payload, user)
        # Generate the params hash.
        parameters = payload['parameters'] || payload['params']

        # Build a request object.
        request = Hg::Request.new(
          user:       user,
          intent:     payload['intent'],
          action:     payload['action'],
          parameters: parameters
        )
      end

      # Build a request object from a referral and user.
      #
      # @param referral [Facebook::Messenger::Incoming::Referral] The postback referral code.
      # @param user [Object] The user that sent the payload.
      #
      # @return [Hg::Request] The generated request.
      def build_referral_request(referral, user)
        payload = JSON.parse(URI.decode(referral.ref))
        build_payload_request(payload['payload'], user)
      end

      # Log an error.
      #
      # @param [Error] e
      #   The error to log.
      #
      # @return [void]
      def log_error(e)
        logger.error e.message
        logger.error e.backtrace.join()
      end

      # Helper for Chatbase API Client
      def chatbase_api_client
        ChatbaseAPIClient.new
      end
    end
  end
end
