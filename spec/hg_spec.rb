require 'support/rails_helper'

describe Hg do
  class Bot
    class Router < Hg::Router; end
  end

  it 'has a version number' do
    expect(Hg::VERSION).not_to be nil
  end

  context 'configuration' do
    describe '.bot_class' do
      it "sets the bot's root class" do
        Hg.bot_class = Bot

        expect(Hg.bot_class).to eq(Bot)
      end
    end

    describe '.router' do
      it "returns the bot's router class" do
        expect(Hg.router).to eq(Bot::Router)
      end
    end

    describe '.user_class' do
      it "sets the bot's user class" do
        Hg.user_class = BotUser

        expect(Hg.user_class).to eq(BotUser)
      end
    end

    describe '.routes' do
      it "returns the bot's routes" do
        expect(Hg.routes).to_not be_nil
      end
    end
  end
end
