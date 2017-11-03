# frozen_string_literal: true

class Hg::UserModelGenerator < Rails::Generators::Base
  desc 'Generate a user model and migration'

  # Generate a new user model.
  def create_user_model
    generate 'model', 'user facebook_psid:string:index api_ai_session_id:string'
  end

  # Enable the hstore extension.
  def enable_hstore
    inject_into_file create_users_migration_path,
                     after: "def change\n" do
      <<-'RUBY'
    enable_extension 'hstore'

      RUBY
    end
  end

  # Add a context field to the migration.
  def add_context_field
    inject_into_file create_users_migration_path,
                     after: "t.string :api_ai_session_id\n" do
      <<-'RUBY'
      t.hstore :context, default: {}
      RUBY
    end
  end

  private

  # Determine the name of the migration file.
  def create_users_migration_path
    @migration_path ||= Dir.glob(File.join(Rails.root, 'db', 'migrate', "*create_users.rb"))[0]
  end
end
