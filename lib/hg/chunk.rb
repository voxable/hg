module Hg
  module Chunk
    class << self
      def included(base)
        base.extend ClassMethods
        base.id = base.to_s
        base.deliverables = []
        base.add_to_router
        base.add_to_chunks
        base.include_chunks
      end
    end

    module ClassMethods
      attr_accessor :id
      attr_accessor :deliverables
      attr_accessor :label

      def bot_class
        self.to_s.split('::').first.constantize
      end

      def label(text)
        @label = text
      end

      def add_to_router
        bot_class.routes.merge(@id.to_sym => self)
      end

      def add_to_chunks
        bot_class.chunks << self
      end

      def include_chunks
        bot_class.class_eval "include #{bot_class.to_s}::Blocks"
      end

      def deliver(recipient)
        show_typing(recipient)

        Rails.logger.ap(@deliverables)

        @deliverables.each do |deliverable|
          if deliverable.is_a? Class
            deliverable.deliver(recipient)
          else
            Facebook::Messenger::Bot.deliver(deliverable.merge(recipient: recipient))
          end
        end
      end

      def show_typing(recipient)
        Facebook::Messenger::Bot.deliver(
          recipient: recipient,
          sender_action: 'typing_on'
        )
      end

      def keywords(*chunk_keywords)
        chunk_keywords.each do |keyword|
          bot_class.routes[keyword] = self
        end
      end

      def text(message)
        @deliverables <<
          {
            message: {
              text: message
            }
          }
      end

      def title(text)
        @card[:title] = text
      end

      def subtitle(text)
        @card[:subtitle] = text
      end

      def image_url(path)
        @card[:image_url] = bot_class.instance_variable_get(:@image_url_base_portion) + path
      end

      def item_url(url)
        @card[:item_url] = url
      end

      def button(text, options = {})
        # TODO: text needs a better name
        if text.is_a? Class
          klass = text
          text = text.instance_variable_get(:@label)

          button_content = {
            title: text,
            type: 'postback',
            payload: klass.to_s
          }
        else
          button_content = {
            title: text
          }
        end

        if options[:to]
          button_content[:type] = 'postback'
          button_content[:payload] = options[:to].to_s
        elsif options[:url]
          button_content[:type] = 'web_url'
          button_content[:url] = options[:url]
        end

        button_content[:webview_height_ratio] = options[:webview_height_ratio]

        @card[:buttons] = [] unless @card[:buttons]

        @card[:buttons] << button_content
      end

      def quick_replies(*classes)
        classes.each do |klass|
          quick_reply klass.instance_variable_get(:@label), to: klass
        end
      end

      def quick_reply(title, options = {})
        quick_reply_content = {
          content_type: 'text',
          title: title,
          payload: options[:to].to_s
        }

        unless @deliverables.last[:message][:quick_replies]
          @deliverables.last[:message][:quick_replies] = []
        end

        @deliverables.last[:message][:quick_replies] << quick_reply_content
      end

      def card(&block)
        @card = {}
        yield
        @gallery[:cards] << @card
      end

      def gallery(&block)
        @gallery = {
          cards: [],
          message: {
            attachment: {
              type: 'template',
              payload: {
                template_type: 'generic',
                elements: []
              }
            }
          }
        }

        yield

        @gallery[:message][:attachment][:payload][:elements] = @gallery.delete(:cards)

        @deliverables << @gallery
      end

      def image(path)
        @deliverables << {
          message: {
            attachment: {
              type: 'image',
              payload: {
                url: bot_class.instance_variable_get(:@image_url_base_portion) + path
              }
            }
          }
        }
      end

      def chunk(chunk_class)
        @deliverables << chunk_class
      end
    end
  end
end
