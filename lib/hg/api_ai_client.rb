# TODO: Test & Document
module Hg
  class ApiAiClient
    def initialize(session_id)
      # TODO: access token should be set by Hg config option
      @client = ApiAiRuby::Client.new(
        client_access_token: ENV['API_AI_CLIENT_ACCESS_TOKEN'],
        api_version: '20170210',
        api_session_id: session_id
      )
    end

    def query(message)
      api_ai_response = @client.text_request(message)

      return nil if api_ai_response[:result][:action] == 'input.unknown'

      {
        intent: api_ai_response[:result][:metadata][:intentName],
        action: api_ai_response[:result][:action],
        parameters: api_ai_response[:result][:parameters]
      }
    end
  end
end
