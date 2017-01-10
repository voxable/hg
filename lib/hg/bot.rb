module Hg
  module Bot
    class << self
      def included(base)
        base.extend ClassMethods
        base.routes = {}
        base.chunks = []
        base.call_to_actions = []
      end
    end

    module ClassMethods
      attr_accessor :routes
      attr_accessor :chunks
      attr_accessor :default_chunk
      attr_accessor :call_to_actions
      attr_accessor :get_started_content
      attr_accessor :greeting_text
      attr_accessor :image_url_base_portion

      def init
        initialize_router
        initialize_persistent_menu
        initialize_get_started_button
        initialize_greeting_text
      end

      def default(chunk)
        @default_chunk = chunk
      end

      def persistent_menu(&block)
        yield
      end

      def initialize_persistent_menu
        Facebook::Messenger::Thread.set(
          setting_type: 'call_to_actions',
          thread_state: 'existing_thread',
          call_to_actions: @call_to_actions
        )
      end

      def call_to_action(text, options = {})
        call_to_action_content = {
          title: text
        }

        if options[:to]
          call_to_action_content[:type] = 'postback'
          call_to_action_content[:payload] = options[:to].to_s
        elsif options[:url]
          call_to_action_content[:type] = 'web_url'
          call_to_action_content[:url] = options[:url]
        end

        @call_to_actions << call_to_action_content
      end

      def get_started(chunk)
        @get_started_content = {
          setting_type: 'call_to_actions',
          thread_state: 'new_thread',
          call_to_actions: [
                          {
                            payload: chunk.to_s
                          }
                        ]
        }
      end

      def initialize_get_started_button
        Facebook::Messenger::Thread.set @get_started_content
      end

      def greeting_text(text)
        @greeting_text = text
      end

      def image_url_base(base)
        @image_url_base_portion = base
      end

      def initialize_greeting_text
        Facebook::Messenger::Thread.set(
          setting_type: 'greeting',
          greeting: {
            text: @greeting_text
          }
        )
      end

      def run_postback_payload(payload, recipient)
        begin
          payload.constantize.deliver(recipient)
        rescue NameError
          Rails.logger.error "Postback payload constant not found: #{payload}"
        end
      end

      def initialize_router
        Facebook::Messenger::Bot.on :postback do |postback|
          #Rails.logger.info 'POSTBACK'
          #Rails.logger.info postback.payload

          run_postback_payload(postback.payload, postback.sender)
        end

        Facebook::Messenger::Bot.on :message do |message|
          #Rails.logger.info 'MESSAGE'
          #Rails.logger.info message.text
          #Rails.logger.info message.quick_reply

          # Attempt to run a quick reply payload
          if message.quick_reply
            run_postback_payload(message.quick_reply, message.sender)
          # Fall back to fuzzy matching keywords
          elsif fuzzy_match = FuzzyMatch.new(@routes.keys).find(message.text)
            @routes[fuzzy_match].deliver(message.sender)
          # Fallback behavior
          else
            @default_chunk.deliver(message.sender)
          end
        end
      end
    end
  end
end
