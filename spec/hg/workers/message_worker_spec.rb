require 'rails_helper'
require_relative './worker_spec_shared_contexts'
require_relative './worker_spec_shared_examples'

RSpec.describe Hg::MessageWorker, type: :worker do
  include_context 'with mocked queue' do
    let(:queue_class) { Hg::Queues::Messenger::MessageQueue }
    let(:queue) { instance_double(queue_class.to_s) }
  end

  include_examples 'a message processing worker'

  context "when a message is present on the user's unprocessed message queue" do
    include_context 'when queue has unprocessed message' do
      let(:text) { 'hi there' }
      let(:message) {
        instance_double(
          'Facebook::Messenger::Incoming::Message',
          sender: { 'id' => user_id },
          text: text
        )
      }
      let(:raw_message) {
        {
          'sender' => {
            'id' => user_id
          },
          'message' => {
            'text' => text
          }
        }
      }
      let(:user_api_ai_session_id) { 's0m3id' }
      let(:user) {
        double(
          'user',
          api_ai_session_id: user_api_ai_session_id,
          context: {}
        )
      }
      let(:api_ai_response) { { intent: 'someintent', action: 'someaction', parameters: { 'foo' => 'bar' } }}
      let(:api_ai_client) {
        instance_double('Hg::ApiAiClient', query: api_ai_response)
      }
      let(:valid_args) { [1, 'foo', 'NewsBot'] }
      let(:payload_hash) {
        {
          'action' => 'someaction',
          'intent' => 'someintent',
          'params' => {
            'foo' => 'bar'
          }
        }
      }
      let(:payload) { JSON.generate(payload_hash)}
      let(:qr_payload_hash) {
        {
          'content_type' => 'text',
          'title'        => 'sometitle',
          'payload'      => payload
        }
      }
      let(:quick_reply) { JSON.generate(qr_payload_hash)}
      let(:raw_message_qr) {
        {
          'sender' => {
            'id' => user_id
          },
          'message' => {
            'text' => text,
            'quick_reply' => qr_payload_hash
          }
        }
      }
      let(:message_qr) {
        instance_double(
          'Facebook::Messenger::Incoming::Message',
          sender: { 'id' => user_id },
          text: text,
          quick_reply: quick_reply
        )
      }
      let(:request) {
        instance_double(
          'Hg::Request',
          payload_hash
        )
      }
    end

    before(:example) do
      allow(queue).to receive(:pop).and_return(raw_message, {})
      allow(Facebook::Messenger::Incoming::Postback).to receive(:initialize).and_return(message)
      allow(bot_class.router).to receive(:handle).with(request)
    end

    include_examples 'constructing a request object'

    context 'when the message is a quick reply' do
      it 'builds a payload request' do
        allow(queue).to receive(:pop).and_return(raw_message_qr, {})
        allow(Facebook::Messenger::Incoming::Message).to receive(:initialize).and_return(message_qr)

        expect(subject).to receive(:build_payload_request).with(payload_hash, user).and_return(request)

        subject.perform(*valid_args)
      end
    end

    context 'when the user is in the midst of a dialog' do
      let(:controller) { class_double("SomeController").as_stubbed_const }
      let(:user_in_dialog) {
        double(
          'user',
          api_ai_session_id: user_api_ai_session_id,
          context: {
            dialog_handler:    'somehandler',
            dialog_controller: controller,
            dialog_parameters: 'someparams'
          }
        )
      }
      let(:dialog_request) { instance_double(
        'Hg::Request',
        intent:     'somehandler',
        action:     'somehandler',
        parameters: 'someparams',
        route: {
          controller: controller,
          handler:    'somehandler'
        })
      }

      before(:example) do
        allow(user_class).to receive(:find_or_create_by).and_return(user_in_dialog)
        allow(Kernel).to receive(:const_get).and_return(bot_class, controller)
      end

      context 'when building a dialog request' do
        it 'adds the dialog handler to the request' do
          allow(bot_class.router).to receive(:handle) do |request|
            expect(request.intent).to eq user_in_dialog.context[:dialog_handler]
          end

          subject.perform(*valid_args)
        end

        it 'adds the parameters to the request' do
          allow(bot_class.router).to receive(:handle) do |request|
            expect(request.parameters).to eq user_in_dialog.context[:dialog_parameters]
          end

          subject.perform(*valid_args)
        end

        it 'adds the dialog controller to the request' do
          allow(bot_class.router).to receive(:handle) do |request|
            expect(request.route[:controller]).to eq user_in_dialog.context[:dialog_controller]
          end

          subject.perform(*valid_args)
        end
      end

      it 'creates the request' do
        expect(subject).to receive(:build_dialog_request).with(user_in_dialog, an_instance_of(Facebook::Messenger::Incoming::Message))

        subject.perform(*valid_args)
      end
    end

    context 'when the message has an attachment' do
      let(:attachments) {
        {
          'type' => 'location',
          'payload' => {
            'coordinates' => {
              'lat' => 'somelatitude',
              'long' => 'somelongitude'
            }
          }
        }
      }
      let(:raw_message_w_attach) {
        {
          'sender' => {
            'id' => user_id
          },
          'message' => {
            'text' => text,
            'attachments' => [attachments]
          }
        }
      }
      let(:message_w_attach) {
        instance_double(
          'Facebook::Messenger::Incoming::Message',
          sender: { 'id' => user_id },
          text: text,
          attachments: attachments
        )
      }
      let(:attach_request) { instance_double(
        'Hg::Request',
        user: user,
        message:    message_w_attach,
        intent:     Hg::InternalActions::HANDLE_COORDINATES,
        action:     Hg::InternalActions::HANDLE_COORDINATES,
        parameters: {
          lat: 'somelatitude',
          long: 'somelongitude'
        })
      }

      before(:example) do
        allow(queue).to receive(:pop).and_return(raw_message_w_attach, {})
        allow(Facebook::Messenger::Incoming::Message).to receive(:initialize).with(raw_message_w_attach).and_return(message_w_attach)
      end

      context 'when the attachment is a location' do
        it 'adds the coordinates to the request' do
          allow(user_class).to receive(:find_or_create_by).and_return(user)
          allow(Hg::Request).to receive(:initialize) { attach_request }

          allow(bot_class.router).to receive(:handle) do |request|
            expect(request.intent).to eq Hg::InternalActions::HANDLE_COORDINATES
          end

          subject.perform(*valid_args)
        end
      end
    end

    before(:example) do
      allow(queue).to receive(:pop).and_return(raw_message, {})
      allow(Facebook::Messenger::Incoming::Message).to receive(:initialize).and_return(message)
      allow(Hg::ApiAiClient).to receive(:new).and_return(api_ai_client)
    end

    context 'sending the message to API.ai for parsing' do
      it 'sets the session ID the API.ai session key for the user' do
        expect(Hg::ApiAiClient).to receive(:new).with(user_api_ai_session_id)

        subject.perform(*valid_args)
      end

      it 'sends the message to API.ai for parsing' do
        expect(api_ai_client).to receive(:query).with(text)

        subject.perform(*valid_args)
      end
    end

    context 'when the message is understood by the API.ai agent' do
      it "sends a request to the bot router's handle method" do
        expect(router_class).to receive(:handle)

        subject.perform(*valid_args)
      end
    end

    context "when the message isn't understood by the API.ai agent", priority: :high do
      let(:nlu_response) {
        {
          intent: 'someintent',
          action: 'default'
        }
      }
      let(:params) { {foo: 'bar'} }

      it 'delivers default chunk to user' do
        allow(subject).to receive(:parse_message).and_return(nlu_response, params)
        allow(bot_class.router).to receive(:handle) do |request|
          expect(request.action).to eq Hg::InternalActions::DEFAULT
        end

        subject.perform(*valid_args)
      end
    end
  end

  context "when no messages are present on the user's unprocessed message queue" do
    before(:example) do
      allow(queue).to receive(:pop).and_return({})
    end

    it 'does nothing' do
      expect(subject.perform(*valid_args)).to be_nil
    end
  end
end
