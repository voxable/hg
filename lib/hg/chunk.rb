module Hg
  module Chunk
    def self.included(base)
      base.extend ClassMethods
      base.prepend Initializer
      base.id = base.to_s
      base.deliverables = []
      base.add_to_router
      base.add_to_chunks
      base.include_chunks
    end

    def deliver
      self.class.show_typing(@recipient)

      Rails.logger.info 'DELIVERABLES'
      Rails.logger.info self.class.deliverables.inspect

      self.class.deliverables.each do |deliverable|
        if deliverable.is_a? Class
          deliverable.new(recipient: @recipient).deliver
        elsif deliverable.is_a? Proc
          old_deliverables = self.class.deliverables.dup
          self.class.deliverables = []

          deliverable.call
          self.class.new(recipient: @recipient, context: @context).deliver

          self.class.deliverables = old_deliverables
        else
          Facebook::Messenger::Bot.deliver(deliverable.merge(recipient: @recipient), access_token: ENV['ACCESS_TOKEN'])
        end
      end
    end

    module Initializer
      def initialize(recipient: nil, context: nil)
        @recipient = recipient
        @context = context
      end
    end

    module ClassMethods
      attr_accessor :id
      attr_accessor :deliverables
      attr_accessor :label
      attr_accessor :recipient
      attr_accessor :context

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
        bot_class.class_eval "include #{bot_class.to_s}::Chunks"
      end

      def dynamic(&block)
        @deliverables << block
      end

      def show_typing(recipient)
        Facebook::Messenger::Bot.deliver({
          recipient: recipient,
          sender_action: 'typing_on'
        }, access_token: ENV['ACCESS_TOKEN'])
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

      # Build a button template message.
      # See https://developers.facebook.com/docs/messenger-platform/send-api-reference/button-template
      def buttons(&block)
        @card = {}

        yield

        deliverable = {
          message: {
            attachment: {
              type: 'template',
              payload: {
                template_type: 'button'
              }
            }
          }
        }

        # Move buttons to proper location
        deliverable[:message][:attachment][:payload][:buttons] = @card.delete(:buttons)
        deliverable[:message][:attachment][:payload][:text] = @deliverables.pop[:message][:text]

        @deliverables << deliverable
      end

      def button(text, options = {})
        # TODO: text needs a better name
        # If the first argument is a chunk, then make this button a link to that chunk
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

        # If a `to` option is present, assume this is a postback link to another chunk.
        if options[:to]
          button_content[:type] = 'postback'
          button_content[:payload] = options[:to].to_s
        # If a `url` option is present, assume this is a webview link button.
        elsif options[:url]
          button_content[:type] = 'web_url'

          button_content[:url] = evaluate_option(options[:url])
        # If a different type of button is specified (e.g. "Log in"), then pass
        # through the `type` and `url`.
        elsif options[:type]
          button_content[:type] = options[:type]

          button_content[:url] = evaluate_option(options[:url])
        end

        # Pass through the `webview_height_ratio` option.
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

      private

      # Take an option, and either call it (if a lambda) or return its value.
      #
      # @param [lambda, String] option Either a lambda to be evaluated, or a value
      # @return [String] The option value
      def evaluate_option(option)
        if option.respond_to?(:call)
          option.call(@context)
        else
          option
        end
      end
    end
  end
end
