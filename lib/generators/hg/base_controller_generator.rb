# frozen_string_literal: true

class BaseControllerGenerator < Rails::Generators::NamedBase
  def create_controller_file
    create_file "app/bot/#{bot_name}_bot/controllers/bot_controller.rb",
                <<-FILE
class #{bot_name}Bot
  module Controllers
    class BotController < Hg::Controller
    end
  end
end

    FILE
  end
end
