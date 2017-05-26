class BotControllerGenerator < Rails::Generators::NamedBase
  def create_controller_file
    create_file "app/bot/#{class_name}_bot/controllers/bot_controller_test.rb",
                <<-FILE
class #{class_name}Bot
  module Controllers
    class BotController < Hg::Controller
    end
  end
end

    FILE
  end
end
