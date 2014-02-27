require 'rails/generators'
require 'rails/generators/migration'

module BookingSync
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.join(File.dirname(__FILE__), 'templates')

      def copy_migrations
        migration_template "create_accounts.rb", "db/migrate/create_accounts.rb"
      end
    end
  end
end
