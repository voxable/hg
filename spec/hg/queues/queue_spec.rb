require 'rails_helper'

describe Hg::Queues::Queue do
  let(:queue_key) { 'somekey' }
  let(:queue_class) { Hg::Queues::Queue }
  let(:queue) { Hg::Queues::Queue.new(queue_key) }
  let(:some_message) { 'some_message' }
  let(:some_other_message) { 'a newer message' }

  describe '.initialize' do
    it 'assigns redis @key' do
      queue = Hg::Queues::Queue.new(queue_key)

      expect(queue.instance_variable_get(:@key)).to eq queue_key
    end
  end

  describe '.pop' do
    before(:each) do
      allow(queue_class).to receive(:initialize).and_return(queue)
    end

    context 'when there are messages on the queue' do
      it 'pops the oldest message off of the given queue' do
        queue.push(some_message)
        queue.push(some_other_message)

        result = queue.pop

        expect(result).to eq some_message
      end

      it 'then pops the next in queue' do
        result = queue.pop

        expect(result).to eq some_other_message
      end
    end

    context 'when there is no message on the queue' do
      let(:empty_queue_key) { 'empty_queue_key' }
      let(:empty_queue) { Hg::Queues::Queue.new(empty_queue_key) }

      it 'returns an empty hash' do
        result = empty_queue.pop

        expect(result).to be_empty
      end
    end
  end

  describe '.push' do
    it 'puts the message on the given queue' do
      allow(Hg::Redis).to receive(:execute).and_return('1')

      result = queue.push(some_message)

      expect(result).to_not eq 0
    end
  end
end
