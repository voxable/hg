require 'rails_helper'

RSpec.describe Hg::ApiAiClient do
  let(:message) { 'somemessage' }
  let(:token) { 'sometoken' }
  let(:session_id) { '123456' }
  let(:api_ai_ruby_client) {
    instance_double('ApiAiRuby::Client')
  }

  before(:example) do
    allow(ApiAiRuby::Client).to receive(:new).and_return(api_ai_ruby_client)
  end

  describe '#initialize' do
    it 'creates api.ai client and sets session_id' do
      result = Hg::ApiAiClient.new(session_id)

      expect(result.instance_variable_get(:@client)['session_id']).to eq session_id
    end
  end

  describe '#query' do
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
        let(:no_action_response) {
          {
            result: {
              metadata: {
                intentName: 'someintent'
              },
              action: '',
              fulfillment: {
                speech: 'someresponse'
              },
              parameters: 'someparams'
            }
          }
        }

        it 'uses intent name' do
          allow(ApiAiRuby::Client).to receive(:text_request).and_return(no_action_response)

          result = subject.query(message)

          expect(result.action).to eq 'someintent'
        end
      end

      context 'when message is not recognized' do
        it 'uses default action'
      end

      context 'when message is recognized' do
        let(:api_ai_response) {
          {
            result: {
              metadata: {
                intentName: 'someintent'
              },
              action: 'someaction',
              fulfillment: {
                speech: 'someresponse'
              },
              parameters: 'someparams'
            },
            status: {
              code: 200
            }
          }
        }
        let(:response_blank_params) {
          {
            result: {
              parameters: {
                thiskey: 'hassomething',
                thatkey: 'alsoiswith',
                butthisemptykey: ''
              }
            }
          }
        }

        before(:example) do
          allow(ApiAiRuby::Client).to receive(:text_request).and_return(api_ai_response)
        end

        it 'returns the response' do
          result = subject.query(message)

          expect(result).to eq api_ai_response
        end

        it 'returns intent name' do
          result = subject.query(message)

          expect(result.intent).to eq 'someintent'
        end

        it 'returns action name' do
          result = subject.query(message)

          expect(result.action).to eq 'someaction'
        end

        it 'returns provided params' do
          result = subject.query(message)

          expect(result.parameters).to eq 'someparams'
        end

        it 'removes blank params' do
          allow(ApiAiRuby::Client).to receive(:text_request).and_return(response_blank_params)

          result = subject.query(message)

          expect(result.parameters).to be hash_excluding(butthisemptykey: '')
        end
      end
    end
  end
end

