module BotRouter
  class Generator < Rails::Generators::NamedBase
    def self.source_root
      File.expand_path("../templates", __FILE__)
    end

    def generate
      template "#{self.class.generator_name}.erb", "app/bot/#{bot_name}/router.rb"
    end
  end
end
