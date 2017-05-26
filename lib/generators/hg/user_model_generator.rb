class Hg::UserModelGenerator < Rails::Generators::Base
  # Generate a user model and migration.
  def create_user_model
    generate 'model', 'user facebook_psid:string:index api_ai_session_id:string'

    # Determine the name of the migration file.
    create_users_migration_path = Dir.glob(File.join(Rails.root, 'db', 'migrate', "*create_users.rb"))[0]


    # Add line enabling hstore
    inject_into_file create_users_migration_path,
                     after: "def change\n" do
      <<-'RUBY'
    enable_extension 'hstore'

      RUBY
    end

    # Add line adding context field
    inject_into_file create_users_migration_path,
                     after: "t.string :api_ai_session_id\n" do
      <<-'RUBY'
      t.hstore :context, default: {}
      RUBY
    end
  end
end
