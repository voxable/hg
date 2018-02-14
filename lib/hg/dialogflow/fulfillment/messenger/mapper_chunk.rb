module Hg
  module Dialogflow
    module Fulfillment
      module Messenger
        class MapperChunk
          include Hg::Chunk
          include MessengerBot::Chunks::BaseQuickReplies

          dynamic do |context|
            if !context['speech'].empty?
              text context['speech']
            else
              cards = []
              images = []

              context['messages'].each do |message|
                next unless message['platform'] == 'facebook'

                # If this isn't a card, render a gallery out of the sequential cards.
                if message['type'] != 1 && cards.any?
                  render_gallery(cards)
                  cards = []
                end

                case message['type']
                when 0
                  render_text_response(message['speech'])
                when 1
                  cards << message
                when 2
                  # render_quick_replies
                when 3
                  images << message['imageUrl']
                when 4
                  # custom payload
                else

                end
              end

              render_gallery(cards) if cards.any?
              # Render a random image if several specified.
              image(images.sample) if images.any?
            end

            # TODO: Pull these out.
            schedule_main_quick_reply
            main_menu_quick_reply
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
                    button_text = button_data['text']
                    postback = button_data['postback']

                    # Todo: Need a better regex, here.
                    if postback.match(/\(\d{3}\)\s\d{3}-\d{4}/)
                      call_button button_text, number: postback
                    else
                      button "🔗 #{button_text}", url: postback
                    end
                  end
                end
              end
            end
          end

          BUTTON_REGEX = /(.*):(https?:\/\/[\S]+)/
          #
          def self.render_text_response(text_response)
            # Create regex to search for text buttons.
            previous_line = nil

            # For each line in the message.
            text_response.split("\n").reject(&:blank?).each do |line|
              if line.match(BUTTON_REGEX)
                label = $1
                url = $2

                buttons do
                  text previous_line

                  button "🔗 #{label}", url: url
                end
              else
                # ...otherwise, render the line as a text message.
                render_previous_line(previous_line)
              end

              previous_line = line
            end

            render_previous_line(previous_line)
          end

          #
          def self.render_previous_line(previous_line)
            return unless previous_line && !previous_line.match(BUTTON_REGEX)

            text previous_line
          end
        end
      end
    end
  end
end
