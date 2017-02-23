require 'support/rails_helper'

describe Hg do
  it 'has a version number' do
    expect(Hg::VERSION).not_to be nil
  end

  context 'configuration' do
    it 'allows setting the bot class'
  end

  context 'accessing bot information' do
    context '.bot' do
      describe '.bot_class' do
        it 'returns the bot class'
      end

      describe '.routes' do
        it "returns the bot's routes"
      end
    end
  end
end
