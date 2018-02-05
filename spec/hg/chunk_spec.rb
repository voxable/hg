# require 'rails_helper'

=begin
class Bot
  include Hg::Messenger::Bot

  module Chunks
  end
end

describe Hg::Chunk do
  describe '#text' do
    class Bot
      module Chunks
        class ChunkWithText
          include Hg::Chunk

          text 'some text'
        end
      end
    end

    it 'generates a proper structured message for a text message' do
      expect(Bot::Chunks::ChunkWithText.deliverables.first).to eq(
        {
          message: {
            text: message
          }
        }
      )
    end
  end
end
=end
