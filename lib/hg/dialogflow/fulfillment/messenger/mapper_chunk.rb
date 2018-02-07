module Hg
  module Dialogflow
    module Fulfillment
      module Messenger
        class MapperChunk
          include Hg::Chunk

          dynamic do |context|
            if !context['speech'].empty?
              text context['speech']
            else
              cards = []

              context['messages'].each do |message|
                next unless message['platform'] == 'facebook'

                # If this isn't a card, render a gallery out of the sequential cards.
                if message['type'] != 1
                  render_gallery(cards)
                  cards = []
                end

                case message['type']
                when 0
                  text message['speech']
                when 1
                  cards << message
                when 2
                  # render_quick_replies
                when 3
                  # render_image
                when 4
                  # custom payload
                else

                end
              end

              render_gallery(cards) if cards.any?

              schedule_main_quick_reply
              main_menu_quick_reply
            end
          end

          #
          def self.render_gallery(messages)
            gallery do
              messages.each do |message|
                card do
                  image_url message['imageUrl'] if message['imageUrl']

                  title message['title']
                  subtitle message['subtitle']

                  message['buttons'].each do |button_data|
                    button button_data['text'], url: button_data['postback']
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
