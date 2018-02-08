# frozen_string_literal: true

# Client used to send metrics to Chatbase, when ENV var present
class ChatbaseAPIClient
  include HTTParty
  base_uri 'https://chatbase.com/api/facebook'

  attr_accessor :intent, :text, :not_handled

  # @return [String] The Chatbase API Key.
  def self.api_key
    ENV['CHATBASE_API_KEY']
  end

  # @return [ChatbaseAPIClient]
  def initialize(params = {})
    @intent = params.fetch(:intent, nil)
    @text = params.fetch(:text, nil)
    @not_handled = params.fetch(:not_handled, false)
  end

  # Sends message sent by user to Chatbase
  #
  # @param [Facebook::Messenger::Incoming::Message|::Postback] message
  #   Hash of message data
  #
  # @return [void]
  def send_user_message(message)
    return unless self.class.api_key

    # Format for Chatbase Facebook API
    message_received = serialize_user_message(message)
    # Post to Chatbase
    catch_errors {
      result = self.class.post(
        "/message_received?api_key=#{self.class.api_key}",
        json_body(message_received)
      )

      result
    }
  end

  # Sends message sent by bot to Chatbase
  #
  # @param [Hash] message
  #   Hash of message data
  # @param [Hash] response
  #   Hash of response data from Facebook
  #
  # @return [void]
  def send_bot_message(message, response)
    # Format for Chatbase Facebook API
    message_body = serialize_bot_message(message, response)
    # Post to Chatbase
    catch_errors{
      result = self.class.post(
        "/send_message?api_key=#{self.class.api_key}",
        json_body(message_body)
      )

      result
    }
  end

  # Method to set chatbase client fields
  #
  # @param [String] intent
  #   Given intent for user message
  # @param [String] text
  #   Text of message or representation of postback
  # @param [Boolean] not_handled
  #   Whether or not user message was understood
  #
  # @return [void]
  def set_chatbase_fields(intent, text, not_handled)
    @intent = intent
    @text = text
    @not_handled = not_handled
  end

  private

  # Formats received message data for Chatbase Facebook API
  #
  # @param [Facebook::Messenger::Incoming::Message|::Postback] message
  #   Hash of message data
  #
  # @return [Hash]
  #   Message data formatted for Chatbase
  def serialize_user_message(message)
    message_received = {
      sender: message.sender,
      recipient: message.recipient,
      timestamp: message.messaging['timestamp'],
      message: {
        mid: message.try(:id),
        text: @text
      },
      chatbase_fields: {
        intent: intent,
        not_handled: not_handled
      }
    }
    message_received
  end

  # Formats sent message data for Chatbase Facebook API
  #
  # @param [Hash, String] message
  #   Message text
  # @param [Hash] response
  #   Response from Facebook
  #
  # @return [Hash]
  #   Message data formatted for Chatbase
  def serialize_bot_message(message, response)
    parsed_response = JSON.parse(response)
    message_body = {
      request_body: {
        recipient: {
          id: parsed_response['recipient_id']
        },
        message: message[:message]
      },
      response_body: parsed_response
    }
    message_body
  end

  # Rescue errors from HTTParty
  #
  # @return [void]
  def catch_errors
    begin
      @response = yield
    rescue HTTParty::Error => e
      connection_errors(e)
    end
  end

  # Logs connections errors rescued, does not raise error
  # Errors to be captured by preferred error tracker
  #
  # @param [error] e
  #   Error captured
  #
  # @return [void]
  def connection_errors(e)
    logger.error 'error with Chatbase API request:'
    logger.error e
    logger.error e.backtrace.join("\n")
  end

  # Generate the proper request options for a JSON request body.
  #
  # @param [Hash] body
  #   The request body.
  #
  # @return [Hash]
  #   The newly generated JSON body with headers.
  def json_body(body)
    {
      body: body.to_json,
      headers: { 'Content-Type' => 'application/json' }
    }
  end
end
