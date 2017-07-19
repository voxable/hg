require 'rails_helper'

RSpec.describe Hg::ApiAiClient do
  let(:message) { 'somemessage' }
  let(:token) { 'sometoken' }
  let(:session_id) { '123456' }
  let(:api_ai_ruby_client) {
    instance_double('ApiAiRuby::Client')
  }
  subject { instance_double('Hg::ApiAiClient') }

  before(:example) do
    allow(ApiAiRuby::Client).to receive(:new).with(
      client_access_token: ENV['API_AI_CLIENT_ACCESS_TOKEN'],
      api_version: '20170210',
      api_session_id: session_id
    ).and_return(api_ai_ruby_client)
  end

  describe '#initialize' do
    it 'creates api.ai client and sets session_id' do
      result = Hg::ApiAiClient.new(session_id)

      expect(result.instance_variable_get(:@client)).to_not be_nil
    end
  end

  describe '#query' do
    before(:example) do
      @api_client = Hg::ApiAiClient.new(session_id)
    end

    context 'when the query request fails' do
      it 'raises QueryError' do
        # allow(api_ai_ruby_client).to receive(:text_request).and_raise(ApiAiRuby::ClientError)
        #
        # expect(@api_client.query(message)).to raise_error(Hg::ApiAiClient::QueryError)
      end
    end

    context 'when the api call returns other than 200' do
      let(:status_404) {
        {
          result: {
            metadata: {
              intentName: 'someintent'
            },
            action: 'someaction',
            fulfillment: {
              speech: 'someresponse'
            },
            parameters: {
              thiskey: 'hassomething',
              butthisemptykey: ''
            }
          },
          status: {
            code: 404
          }
        }
      }
      it 'returns the default action' do
        allow(api_ai_ruby_client).to receive(:text_request).and_return(status_404)

        result = @api_client.query(message)

        expect(result[:action]).to eq Hg::InternalActions::DEFAULT
      end
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
              parameters: { params: 'someparams' }
            },
            status: {
              code: 200
            }
          }
        }

        it 'uses intent name' do
          allow(api_ai_ruby_client).to receive(:text_request).and_return(no_action_response)

          result = @api_client.query(message)

          expect(result[:action]).to eq 'someintent'
        end
      end

      context 'when message is not recognized' do
        let(:unknown_action) {
          {
            result: {
              metadata: {
                intentName: 'someintent'
              },
              action: 'input.unknown',
              fulfillment: {
                speech: 'someresponse'
              },
              parameters: { params: 'someparams' }
            },
            status: {
              code: 200
            }
          }
        }

        it 'uses default action' do
          allow(api_ai_ruby_client).to receive(:text_request).and_return(unknown_action)

          result = @api_client.query(message)

          expect(result[:action]).to eq Hg::InternalActions::DEFAULT
        end
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
              parameters: {
                thiskey: 'hassomething',
                butthisemptykey: ''
              }
            },
            status: {
              code: 200
            }
          }
        }

        before(:example) do
          allow(api_ai_ruby_client).to receive(:text_request).and_return(api_ai_response)
        end

        it 'returns intent name' do
          result = @api_client.query(message)

          expect(result[:intent]).to eq 'someintent'
        end

        it 'returns action name' do
          result = @api_client.query(message)

          expect(result[:action]).to eq 'someaction'
        end

        #TODO: does #parsed_params actually remove blank keys?
        it 'removes blank params'
          # result = @api_client.query(message)
          #
          # expect(result[:parameters]).to be hash_not_including(:butthisemptykey)
      end
    end
  end
end

