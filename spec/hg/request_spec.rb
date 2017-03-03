require 'support/rails_helper'

describe Hg::Request do
  context 'initializing' do
    context 'when no user is provided' do
      it 'throws an error' do
        expect {
          Hg::Request.new({
            action: 'searchSchedule',
            intent: 'searchSchedule',
            message: Object.new,
            parameters: {
              artist_name: 'Father John Misty'
           }
          })
        }.to raise_error(ArgumentError)
      end
    end

    context 'when no message is provided' do
      it 'throws an error' do
        expect {
          Hg::Request.new({
                            action: 'searchSchedule',
                            intent: 'searchSchedule',
                            user: Object.new,
                            parameters: {
                              artist_name: 'Father John Misty'
                            }
                          })
        }.to raise_error(ArgumentError)
      end
    end

    context 'when no intent is provided' do
      it 'throws an error' do
        expect {
          Hg::Request.new({
            user: Object.new,
            action: 'searchSchedule',
            message: Object.new,
            parameters: {
              artist_name: 'Father John Misty'
            }
          })
        }.to raise_error(ArgumentError)
      end
    end

    context 'when no action is provided' do
      it 'throws an error' do
        expect {
          Hg::Request.new({
            user: Object.new,
            intent: 'searchSchedule',
            message: Object.new,
            parameters: {
              artist_name: 'Father John Misty'
            }
          })
        }.to raise_error(ArgumentError)
      end
    end

    context 'when no parameters are provided' do
      it 'throws an error' do
        expect {
          Hg::Request.new({
            user: Object.new,
            message: Object.new,
            action: 'searchSchedule',
            intent: 'searchSchedule'
          })
        }.to raise_error(ArgumentError)
      end
    end
  end
end
