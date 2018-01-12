# frozen_string_literal: true

# Client used to send metrics to Chatbase, when ENV var present
class ChatbaseAPIClient
  include HTTParty
  BASE_PATH = 'https://chatbase.com/api/facebook'

  # Sends message sent by user to Chatbase
  def send_user_message(message)
    catch_errors{
      self.class.post("#{BASE_PATH}/message_received?api_key=#{ENV['CHATBASE_API_KEY']}", json_body(message))
    }
  end

  # Sends message sent by bot to Chatbase
  def send_bot_message(message)
    catch_errors{
      self.class.post("#{BASE_PATH}/send_message?api_key=#{ENV['CHATBASE_API_KEY']}", json_body(message))
    }
  end

  private

  def catch_errors
    begin
      @response = yield
    rescue HTTParty::Error => e
      connection_errors(e)
    end
    error_codes(@response)
  end

  # Logs connections errors during communication
  def connection_errors(e)
    logger.error 'error with Chatbase API request:'
    logger.error e
    logger.error e.backtrace.join("\n")
  end

  # Generate the proper request options for a JSON request body.
  #
  # @param body [Hash]
  #   The request body.
  #
  # @return [Hash]
  #   The newly generated options.
  def json_body(body)
    {
      body: body.to_json,
      headers: { 'Content-Type' => 'application/json' }
    }
  end
end
