require 'rails_helper'
require_relative './worker_spec_shared_contexts'
require_relative './worker_spec_shared_examples'

RSpec.describe Hg::PostbackWorker, type: :worker do
  include_context 'with mocked queue' do
    let(:queue_class) { Hg::Queues::Messenger::PostbackQueue }
    let(:queue) { instance_double(queue_class.to_s) }
  end

  include_examples 'a message processing worker'

  context "when a postback is present on the user's unprocessed postback queue" do
    include_context 'when queue has unprocessed message' do
      let(:payload_hash) {
        {
          'action' => 'someaction',
          'intent' => 'someintent',
          'params' => {
            'foo:' => 'bar'
          }
        }
      }
      let(:payload) { JSON.generate( payload_hash )}
      let(:postback) {
        instance_double(
          'Facebook::Messenger::Incoming::Postback',
          sender: { 'id' => user_id },
          payload: payload
        )
      }
      let(:raw_postback) {
        {
          'sender' => {
            'id' => user_id,
          },
          'postback' => {
            'payload' => payload
          }
        }
      }
      let(:valid_args) { [1, 'foo', 'NewsBot'] }
      let(:request) {
        instance_double(
          Hg::Request,
          payload_hash
        )
      }
    end

    before(:example) do
      allow(queue).to receive(:pop).and_return(raw_postback, {})
      allow(Facebook::Messenger::Incoming::Postback).to receive(:initialize).and_return(postback)
      allow(bot_class.router).to receive(:handle).with(request)
    end

    include_examples 'constructing a request object'

    context 'when the postback is a referral' do
      let(:referral_payload) {
        {
          'ref' => JSON.generate(
            {
              'payload' => {
                'action' => 'someaction',
                'params' => {
                  'invite_code' => 'somerefcode'
                }
              }
            }
          )
        }
      }
      let(:ref_payload) { instance_double(
          'Facebook::Messenger::Incoming::Postback',
          referral: referral_payload
        )
      }
      let(:raw_referral) {
        {
          'sender' => {
            'id' => user_id,
          },
          'postback' => {
            'payload' => payload,
            'referral' => referral_payload
          }
        }
      }
      let(:ref_request) {
        instance_double(
          Hg::Request,
          'action' => 'someaction',
          'params' => {
            'invite_code' => 'somerefcode'
          }
        )
      }

      before(:example) do
        allow(queue).to receive(:pop).and_return(raw_referral, {})
      end

      it 'processes as referral' do
        expect(subject).to receive(:build_referral_request)

        subject.perform(*valid_args)
      end

      it 'adds the ref to the payload' do
        expect(subject).to receive(:build_payload_request).and_return(ref_request)

        subject.perform(*valid_args)
      end
    end
  end

  context "when no postbacks are present on the user's unprocessed postback queue" do
    it 'does nothing' do
      allow(queue).to receive(:pop).and_return({})

      expect(subject.perform(*valid_args)).to be_nil
    end
  end
end
