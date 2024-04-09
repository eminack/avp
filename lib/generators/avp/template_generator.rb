require 'rails/generators'

module AVP
  class TemplateGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates/', __dir__)

    argument :name, type: :string

    def create_template_file
      template 'policy_template.txt.erb', "app/policies/#{file_name}.rb"
    end

    private

    def file_name
      name.underscore
    end

    def class_name
      name.camelize
    end
  end
end
