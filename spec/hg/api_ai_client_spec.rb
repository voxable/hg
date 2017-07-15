require 'rails_helper'

RSpec.describe Hg::ApiAiClient do
  let(:message) { 'somemessage' }
  let(:token) { 'sometoken' }
  let(:session_id) { '123456' }
  let(:api_ai_response) { { intent: nil, action: nil, parameters: { foo: 1 } }}
  let(:api_ai_ruby_client) {
    instance_double('ApiAiRuby::Client')
  }

  before(:example) do
    allow(ApiAiRuby::Client).to receive(:new).and_return(api_ai_ruby_client)
  end

  describe '.initialize' do
    it 'creates api.ai client' do
      result = Hg::ApiAiClient.new(session_id)

      expect(result.instance_variable_get(:@client)).to_not be_nil
    end

    context 'setting @client' do
      it 'has a client access token'

      it 'has the api version'

      it 'has the session_id'
    end
  end

  describe '.query' do
    context 'when the query request fails' do
      it 'logs error to Sidekick::Logger'

      it 'retries 3 times'

      it 'raises QueryError'
    end

    context 'when the api call returns other than 200' do
      it 'logs to Sidekick'

      it 'returns the default action'
    end

    context 'with valid query/response' do
      context 'with no action name defined for intent' do
        it 'uses intent name'
      end

      context 'when message is not recognized' do
        it 'uses default action'
      end

      context 'when message is recognized' do
        it 'returns intent name'

        it 'returns action name'

        it 'returns provided params'

        it 'removes blank params'

        it 'returns response'
      end
    end
  end
end

