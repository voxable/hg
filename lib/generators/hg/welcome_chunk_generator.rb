class WelcomeChunkGenerator < Rails::Generators::NamedBase
  def create_controller_file
    create_file "app/bot/#{class_name}_bot/chunks/welcome.rb",
                <<-FILE
require 'hg'

class #{class_name}Bot
  module Chunks
    class Welcome
      include Hg::Chunk

      text "Welcome! You're seeing the default Hg Chunk!"

    end
  end
end

    FILE
  end
end
