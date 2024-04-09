require 'avp/configuration'
require 'avp/attribute_schema_serializer'
require 'avp/resource'
require 'avp/principal'
require 'avp/policy_template'
require 'avp/static_policy'
require 'generators/avp/migrate_generator'
require 'generators/avp/static_policy_generator'
require 'generators/avp/template_generator'
require 'avp/inflections'
require 'avp/schema_service'
require 'avp/policy_service'
require 'avp/static_policy_service'
require 'avp/policy_template_service'
require 'rake'

module AVP
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
    raise 'AVP: Scope OR Store not set' unless configuration.default_scope && configuration.default_store
  end
end

# load all rake tasks
task_dir = File.expand_path('tasks/', __dir__)
Dir[File.join(task_dir, '*.rake')].each { |file| Rake.application.add_import(file) }
