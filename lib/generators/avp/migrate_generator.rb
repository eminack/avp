require 'rails/generators'
require 'rails/generators/migration'

module AVP
  class MigrateGenerator < Rails::Generators::Base
    include Rails::Generators::Migration
    source_root File.expand_path('templates/', __dir__)

    def create_template_file
      migration_template 'create_avp_policy.rb', 'db/migrate/create_avp_policy.rb'
    end

    def self.next_migration_number(_path)
      Time.now.utc.strftime('%Y%m%d%H%M%S')
    end
  end
end
