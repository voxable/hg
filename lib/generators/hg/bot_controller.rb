# frozen_string_literal: true

module BotController
  class Generator < Rails::Generators::NamedBase
    def self.source_root
      File.expand_path("../templates", __FILE__)
    end

    def generate
      template "#{self.class.generator_name}.erb", "app/bot/#{bot_name}/controllers/#{file_name}.rb"
    end
  end
end
