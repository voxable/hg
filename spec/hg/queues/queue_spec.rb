require 'rails_helper'

describe Hg::Queues::Queue do
  let(:queue_key) { 'somekey' }
  let(:queue_class) { Hg::Queues::Queue }
  let(:queue) { Hg::Queues::Queue.new(queue_key) }
  let(:some_message) { 'some_message' }
  let(:some_other_message) { 'a newer message' }
  let(:conn) { double('conn') }

  before(:example) do
    allow(queue_class).to receive(:initialize).and_return(queue)
    allow(Hg::Redis).to receive(:execute).and_yield(conn)
  end

  describe '.initialize' do
    it 'assigns redis @key' do
      queue = Hg::Queues::Queue.new(queue_key)

      expect(queue.instance_variable_get(:@key)).to eq queue_key
    end
  end

  describe '.pop' do
    context 'when there are messages on the queue' do
      it 'pops the oldest message off of the given queue' do
        allow(conn).to receive(:lpop).and_return(JSON.generate(some_message))

        result = queue.pop

        expect(result).to eq some_message
      end
    end

    context 'when there is no message on the queue' do
      it 'returns an empty hash' do
        allow(conn).to receive(:lpop).and_return(nil)

        result = queue.pop

        expect(result).to eq({})
      end
    end
  end

  describe '.push' do
    it 'puts the message on the given queue' do
      allow(conn).to receive(:rpush).and_return(JSON.generate('1'))

      result = queue.push(some_message)

      expect(result).to_not eq 0
    end
  end
end
