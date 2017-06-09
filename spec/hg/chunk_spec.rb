require 'rails_helper'


class Bot
  include Hg::Messenger::Bot

  module Chunks
  end
end

describe Hg::Chunk do
  let(:test_chunk){
    class Bot
      module Chunks
        class DummyChunk
          include Hg::Chunk
        end
      end
    end
  }
  let(:deliverables){Bot::Chunks::DummyChunk.deliverables}

  describe '#text' do
    let(:some_text){'some text'}
    it 'generates a proper structured message for a text message' do
      test_chunk.text(some_text)
      expect(deliverables.first).to eq(
        {
          message: {
            text: some_text
          }
        }
      )
    end
  end

  describe 'attachments' do
    let(:attachment){deliverables.first[:message][:attachment]}
    let(:some_url){'www.example.com'}
    describe '#image' do
      it 'generates a proper structured message for a image message' do
        test_chunk.image(some_url)
        expect(attachment[:type]).to eq('image')
        expect(attachment[:payload][:url]).to eq(some_url)
      end
    end

    describe '#video' do
      let(:some_url){'www.example.com'}
      it 'generates a proper structured message for a video message' do
        test_chunk.video(some_url)
        expect(attachment[:type]).to eq('video')
        expect(attachment[:payload][:url]).to eq(some_url)
      end
    end
  end

  describe '#gallery' do
    context 'when passed no cards ' do
      it 'creates an empty gallery' do
        l = lambda {}
        expect { test_chunk.gallery(&l) }.to raise_error(Hg::Errors::EmptyGalleryError)

      end
    end
  end
end

