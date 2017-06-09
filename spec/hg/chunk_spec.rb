require 'rails_helper'


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
            text: 'some text'
          }
        }
      )
    end
  end

  describe '#attachment' do
    let(:type){'image'}
    let(:url){'www.example.com'}

    it 'generates a proper structured message for a text message' do

      class Bot
        module Chunks
          class ChunkWithAttachment
            include Hg::Chunk

            attachment(:type, :url)
          end
        end
      end
      expect(Bot::Chunks::ChunkWithAttachment.deliverables.first).to eq(
       {
         message: {
           attachment: {
             type: :type,
             payload: {
               url: :url
             }
           }
         }
       })
    end

  end
end

