# frozen_string_literal: true

module Hg
  # Error thrown when no router class exists.
  class NoRouterClassExistsError < StandardError
    def initialize
      super('No Router class exists for this bot. Define a nested class Router, or set with router=')
    end
  end

  # Error thrown when no user class exists.
  class NoUserClassExistsError < StandardError
    def initialize
      super('No User class exists for this bot. Define a global class User, or set with user_class=')
    end
  end

  module Messenger
    module Bot
      def self.included(base)
        base.extend ClassMethods
        base.chunks = []
        base.call_to_actions = []
        base.nested_call_to_actions = []
        base.nested_menu_items =[]

        # TODO: Need to figure this out.
        # Since the class itself represents the bot, it must be immutable for thread-safety.
        # base.freeze
      end

      # Ensure Controllers constant in bot class is defined for router.
      module Controllers; end

      module ClassMethods
        def init
          subscribe_to_messages
          initialize_message_handlers
          initialize_get_started_button
          initialize_persistent_menu
          initialize_greeting_text
        end

        # The Facebook Page access token
        attr_writer :access_token

        def access_token
          @access_token || ENV['FB_ACCESS_TOKEN']
        end

        # The class representing users.
        attr_writer :user_class

        # @return [Class] The class representing bot users.
        def user_class
          @user_class ||= Kernel.const_get(:User)
        rescue NameError
          raise NoUserClassExistsError.new
        end

        attr_accessor :chunks
        attr_accessor :call_to_actions
        attr_accessor :nested_call_to_actions
        attr_accessor :input_disabled
        attr_accessor :image_url_base_portion
        attr_accessor :nested_menu_items

        # The class representing the router.
        attr_writer :router

        # @return [Class] The bot's router class.
        def router
          @router ||= const_get(:Router)
        rescue LoadError
          raise NoRouterClassExistsError.new
        end

        def persistent_menu(&block)
          yield
        end

        # Enable free-text input for the bot.
        #
        # @see https://developers.facebook.com/docs/messenger-platform/messenger-profile/persistent-menu
        #
        # @return [void]
        def enable_input
          @input_disabled = false
        end

        def nested_menu(title, &block)
          yield

          @nested_menu = {
              title: title,
              type: 'nested',
              call_to_actions: @nested_call_to_actions
          }
          @call_to_actions << @nested_menu
        end

        def menu_item(text, options = {})
          @call_to_actions << call_to_action(text, options)
        end

        def nested_menu_item(text, options = {})
          @nested_call_to_actions << call_to_action(text, options)
        end

        # Subscribe to Facebook message webhook notifications.
        def subscribe_to_messages
          Facebook::Messenger::Subscriptions.subscribe(access_token: ENV['FB_ACCESS_TOKEN'])
        end

        def initialize_persistent_menu
          Facebook::Messenger::Profile.set({
            persistent_menu: [
              locale: 'default',
              composer_input_disabled: @input_disabled,
              call_to_actions: @call_to_actions
            ]
          }, access_token: access_token)
        end

        def call_to_action(text, options = {})
          call_to_action_content = {
            title: text
          }

          # TODO: This duplicates code in Chunk.button. Should be abstracted.
          if options[:to]
            call_to_action_content[:type] = 'postback'
            call_to_action_content[:payload] = JSON.generate({
              action: Hg::InternalActions::DISPLAY_CHUNK,
              parameters: {
                chunk: options[:to].to_s
              }
            })
          elsif options[:url]
            call_to_action_content[:type] = 'web_url'
            call_to_action_content[:url] = options[:url]
          elsif options[:payload]
            call_to_action_content[:type] = 'postback'
            # Encode the payload hash as JSON.
            call_to_action_content[:payload] = JSON.generate(options[:payload])
          end

          call_to_action_content
        end

        # Set the postback payload for the Get Started button.
        #
        # @param payload [Hash] The postback payload.
        #
        # @see https://developers.facebook.com/docs/messenger-platform/messenger-profile/get-started-button
        #
        # @return [void]
        def get_started(payload)
          if payload[:to]
            @get_started_content = {
              get_started: {
                payload: {
                  action: Hg::InternalActions::DISPLAY_CHUNK,
                  parameters: {
                    chunk: payload[:to].to_s
                  }
                }
              }
            }
          else
            @get_started_content = {
              get_started: {
                payload: JSON.generate(payload)
              }
            }
          end
        end

        # Initialize the Get Started button payload setting.
        def initialize_get_started_button
          Facebook::Messenger::Profile.set @get_started_content, access_token: access_token
        end

        def greeting_text(text)
          @greeting_text = text
        end

        def image_url_base(base)
          @image_url_base_portion = base
        end

        def initialize_greeting_text
          Facebook::Messenger::Profile.set({
            greeting: [
                locale: 'default',
              text: @greeting_text
            ]
          }, access_token: access_token)
        end

        # Generate a redis namespace, based on the class's name.
        #
        # @return [String] The redis namespace
        def redis_namespace
          self.to_s.tableize
        end

        # Queue a postback for processing.
        #
        # @param postback [Facebook::Messenger::Incoming::Postback / ::Referral]
        #   The postback/referral to be queued.
        def queue_postback(postback)
          # Grab the user's PSID.
          user_id = postback.sender['id']
          # Pull out the raw JSON postback from the `Postback` object.
          raw_postback = postback.messaging

          # Handle referral
          if raw_postback['referral']
            # 'ref' value is parsed json, set to 'postback' key
            payload = raw_postback['referral']['ref']
            raw_postback['postback'] = payload
          # Else, it may be a referral, but Get Started postback has been received
          elsif raw_postback['postback']['referral']
            payload = raw_postback['postback']['referral']['ref']
            # Parse the payload and set to 'postback'
            raw_postback['postback'] = JSON.parse(payload)
          # ...else, it's a standard postback
          else
            # Parse the postback payload as JSON, and store it as the value of
            # the `payload` key
            raw_payload = raw_postback['postback']['payload']
            raw_postback['postback']['payload'] = JSON.parse(raw_payload)
          end

          # Store the transformed postback on the queue
          Hg::Queues::Messenger::PostbackQueue
            .new(user_id: user_id, namespace: redis_namespace)
            .push(raw_postback)

          # Queue postback for processing.
          Hg::PostbackWorker.perform_async(user_id, redis_namespace, self.to_s)
        end

        # Queue a message for processing.
        #
        # @param message [Facebook::Messenger::Incoming::Message] The message to be queued.
        def queue_message(message)
          # Store message on this user's queue of unprocessed messages.
          user_id = message.sender['id']
          Hg::Queues::Messenger::MessageQueue
            .new(user_id: user_id, namespace: redis_namespace)
            .push(message.messaging)

          # Queue message for processing.
          Hg::MessageWorker.perform_async(user_id, redis_namespace, self.to_s)
        end

        # Show a typing indicator to the user.
        #
        # @param recipient_id [String] The Facebook PSID of the user that will see the indicator
        def show_typing(recipient_psid)
          Facebook::Messenger::Bot.deliver({
             recipient: {id: recipient_psid},
             sender_action: 'typing_on'
           }, access_token: access_token)
        end

        # Initialize the postback and message handlers for the bot, which will
        # queue the messages for processing.
        def initialize_message_handlers
          ::Facebook::Messenger::Bot.on :postback do |postback|
            begin
              # Show a typing indicator to the user
              show_typing(postback.sender['id'])

              # TODO: Build a custom logger, make production logging optional
              # Log the postback
              Rails.logger.info "POSTBACK: #{postback.payload}"

              # Queue the postback for processing
              queue_postback(postback)
            rescue StandardError => e
              # TODO: high
              Rails.logger.error e.inspect
              Rails.logger.error e.backtrace
            end
          end

          ::Facebook::Messenger::Bot.on :message do |message|
            begin
              # TODO: Build a custom Rails.logger, make production logging optional
              # Log the message
              Rails.logger.info "MESSAGE: #{message.text}"

              # Show a typing indicator to the user
              show_typing(message.sender['id'])

              # Queue the message for processing
              queue_message(message)
            rescue StandardError => e
              # TODO: high
              Rails.logger.error e.inspect
              Rails.logger.error e.backtrace
            end
          end

          ::Facebook::Messenger::Bot.on :referral do |referral|
            begin
              # Log the referral receipt
              Rails.logger.info "Referral from sender: #{referral.sender['id']}"

              # Show a typing indicator to the user
              show_typing(referral.sender['id'])

              # Queue the referral for processing
              queue_postback(referral)
            rescue StandardError => e
              # TODO: high
              Rails.logger.error e.inspect
              Rails.logger.error e.backtrace
            end
          end
        end
      end
    end
  end
end
