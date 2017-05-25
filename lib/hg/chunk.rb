# frozen_string_literal: true

module Hg
  module Chunk
    def self.included(base)
      base.extend ClassMethods
      base.prepend Initializer
      base.id = base.to_s
      base.deliverables = []
      base.dynamic = false
      base.add_to_chunks
      base.include_chunks
    end


    # @return [OpenStruct] The execution context for this chunk instance.
    def context
      @memoized_context ||= @context
    end

    def deliver
      Sidekiq::Logging.logger.info 'DELIVERABLES'
      self.class.deliverables.each do |deliverable|
        if deliverable.is_a? Hash
          Sidekiq::Logging.logger.info JSON.pretty_generate(deliverable)
        else
          Sidekiq::Logging.logger.info deliverable.inspect
        end
      end
      Sidekiq::Logging.logger.info 'RECIPIENT'
      Sidekiq::Logging.logger.info @recipient.inspect

      self.class.deliverables.each do |deliverable|
        # If another chunk...
        if deliverable.is_a? Class
          # ...deliver the chunk.
          deliverable.new(recipient: @recipient, context: context).deliver

        # If dynamic, then it needs to be evaluated at delivery time.
        elsif deliverable.is_a? Proc
          # Create a `template` anonymous subclass of the chunk class.
          template = Class.new(self.class)
          template.deliverables = []

          # Evaluate the dynamic block within it.
          template.class_exec(context, &deliverable)

          # Deliver the chunk.
          template.new(recipient: @recipient, context: context).deliver

        # Otherwise, it's just a raw message.
        else
          # Deliver the message
          Facebook::Messenger::Bot.deliver(deliverable.merge(recipient: @recipient), access_token: ENV['FB_ACCESS_TOKEN'])
        end
      end
    end

    module Initializer
      def initialize(recipient: nil, context: nil)
        # TODO: test
        # Ensure recipient is transformed into a Hash
        if recipient.is_a? Hash
          @recipient = recipient
        else
          @recipient = {
            'id': recipient
          }
        end

        @context = HashWithIndifferentAccess.new(context)
      end
    end

    module ClassMethods
      attr_accessor :id
      attr_accessor :deliverables
      attr_accessor :label
      attr_accessor :recipient
      attr_accessor :context
      attr_accessor :dynamic

      def bot_class
        Kernel.const_get(self.to_s.split('::').first)
      end

      def label(text)
        @label = text
      end

      def add_to_chunks
        bot_class.chunks << self
      end

      def include_chunks
        bot_class.class_eval "include #{bot_class.to_s}::Chunks"
      end

      def dynamic(&block)
        @dynamic = true

        @deliverables << block
      end

      def show_typing(recipient)
        Facebook::Messenger::Bot.deliver({
          recipient: recipient,
          sender_action: 'typing_on'
        }, access_token: ENV['FB_ACCESS_TOKEN'])
      end

      def keywords(*chunk_keywords)
        #chunk_keywords.each do |keyword|
        #  bot_class.routes[keyword] = self
        #end
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

      def image_url(url, options = {})
        if options.has_key?(:host)
          @card[:image_url] = ApplicationController.helpers.image_url(url, options)
        else
          @card[:image_url] = url
        end
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

      # TODO: should log_in and log_out be log_in_button and log_out_button?
      def log_in(url)
        button nil, url: url, type: 'account_link'
      end

      def log_out
        button nil, type: 'account_unlink'
      end

      # Add a call button to a card.
      #
      # @param text [String]
      #   The text to appear in the button.
      # @param number [String]
      #   The number to call when the button is pressed.
      #
      # @see https://developers.facebook.com/docs/messenger-platform/send-api-reference/call-button
      #
      # @return [void]
      def call_button(text, number:)
        add_button({
          type:    'phone_number',
          title:   text,
          payload: number
        })
      end

      # Add a share button to a card.
      #
      # @param text [String]
      #   The text to appear in the button.
      # @param content [String]
      #   The share email view
      #
      # @see https://developers.facebook.com/docs/messenger-platform/send-api-reference/share-button
      #
      # @return [void]
      def share_button(text, options = {})
        add_button({
                     type:    'element_share',
                     title:   text,
                     share_contents:  JSON.generate({
                                                      action: Hg::InternalActions::DISPLAY_CHUNK,
                                                      parameters: {
                                                        chunk: options[:chunk]
                                                      }
                                                    })
                   })
      end

      # TODO: High - buttons need their own module
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
          button_content[:payload] = JSON.generate({
            action: Hg::InternalActions::DISPLAY_CHUNK,
            parameters: {
              chunk: options[:to].to_s
            }
          })
        # If a different type of button is specified (e.g. "Log in"), then pass
        # through the `type` and `url`.
        elsif options[:type]
          button_content[:type] = options[:type]

          button_content[:url] = evaluate_option(options[:url])
        # If a `url` option is present, assume this is a webview link button.
        elsif options[:url]
          button_content[:type] = 'web_url'

          button_content[:url] = evaluate_option(options[:url])
        elsif options[:payload]
          button_content[:type] = 'postback'
          # Encode the payload hash as JSON.
          button_content[:payload] = JSON.generate(options[:payload])
        end

        # Pass through the `webview_height_ratio` option.
        button_content[:webview_height_ratio] = options[:webview_height_ratio]

        add_button(button_content)
      end

      def add_button(button_content)
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
          title: title
        }

        # If a `to` option is present, assume this is a postback link to another chunk.
        if options[:to]
          quick_reply_content[:payload] = JSON.generate({
            action: Hg::InternalActions::DISPLAY_CHUNK,
            parameters: {
              chunk: options[:to].to_s
            }
          })
        # If this is a location request, send the appropriate options.
        elsif options[:location_request]
          quick_reply_content[:content_type] = 'location'
          quick_reply_content[:title] = nil
        # Otherwise, just take the payload as passed.
        else
          quick_reply_content[:payload] = JSON.generate(options[:payload])
        end

        unless @deliverables.last[:message][:quick_replies]
          @deliverables.last[:message][:quick_replies] = []
        end

        @deliverables.last[:message][:quick_replies] << quick_reply_content
      end

      # Generate a quick reply button that requests the user's location.
      def quick_reply_location_request
        quick_reply nil, location_request: true
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

      def image(url)
        attachment('image', url)
      end

      def video(url)
        attachment('video', url)
      end

      def chunk(chunk_class)
        @deliverables << chunk_class
      end

      def t(*args)
        I18n.t(*args)
      end

      private

      # Take an option, and either call it (if a lambda) or return its value.
      #
      # @param [lambda, String] option Either a lambda to be evaluated, or a value
      # @return [String] The option value
      #
      # TODO: Is this method still necessary? Only place it's used doesn't seem to
      #   make use of this functionality.
      def evaluate_option(option)
        if option.respond_to?(:call)
          # TODO: BUG - @context is a class instance variable, this isn't going to work correctly
          option.call(@context)
        else
          option
        end
      end

      def attachment(type, url)
        @deliverables << {
          message: {
            attachment: {
              type: type,
              payload: {
                url: url
              }
            }
          }
        }
      end
    end
  end
end
