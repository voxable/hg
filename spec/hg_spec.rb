require 'support/rails_helper'

describe Hg do
  class Bot
    class Router < Hg::Router; end
  end

  it 'has a version number' do
    expect(Hg::VERSION).not_to be nil
  end

  context 'configuration' do
    before(:example) do
      Hg.bot_class = Bot
    end

    describe '.bot_class' do
      it "sets the bot's root class" do
        expect(Hg.bot_class).to eq(Bot)
      end
    end

    describe '.routes' do
      it "returns the bot's routes" do
        expect(Hg.routes).to_not be_nil
      end
    end
  end
end
