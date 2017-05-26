class BotRouterGenerator < Rails::Generators::NamedBase
  def create_controller_file
    create_file "app/bot/#{class_name}_bot/router.rb",
                <<-FILE
require_relative 'controllers/welcome_controller'

class #{class_name}Bot::Router < Hg::Router
  include #{class_name}Bot::Actions

  controller #{class_name}Bot::Controllers::WelcomeController do
    handler GET_STARTED, :welcome
  end

  # Smalltalk domain
  SMALLTALK_ACTIONS = %w(
    smalltalk.agent
    smalltalk.appraisal
    smalltalk.confirmation
    smalltalk.dialog
    smalltalk.emotions
    smalltalk.greetings
    smalltalk.person
    smalltalk.topics
    smalltalk.unknown
    smalltalk.user
  ).freeze

  SMALLTALK_ACTIONS.each do |smalltalk_action|
    action smalltalk_action,
           controller: ::#{class_name}Bot::Controllers::DefaultController,
           with:       :smalltalk
  end
end

    FILE
  end
end
