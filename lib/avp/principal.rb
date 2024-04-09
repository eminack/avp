require 'avp/principal/policy'
require 'avp/dto/principal_identifier'
require 'avp/dto/entity_definition'
require 'avp/dto/model_schema'
require 'avp/dto/entity_schema'
require 'avp/dto/action_schema'
require 'avp/enums/entity_type'

module AVP
  module Principal
    def self.included(base)
      base.extend(ClassMethods)
      base.define_singleton_method :avp_configuration_definition do |input|
        self.class.avp_configuration(input.first)
      end
    end

    module ClassMethods
      def avp_configuration(*args)
        args = args.first
        avp_name(args[:name])
        avp_store(args[:store])
        avp_scope(args[:scope])
        avp_attribute_serializer(args[:attribute_serializer])
        avp_identifier(args[:identifier])
        avp_parents(args[:parents])
      end

      def avp_name(model_name)
        define_singleton_method(:avp_name) do
          model_name.to_s
        end
        avp_name
      end

      def avp_store(store_id = nil)
        define_singleton_method(:avp_store) do
          store_id || ::AVP.configuration.default_store
        end
        avp_store
      end

      def avp_scope(model_scope = nil)
        define_singleton_method(:avp_scope) do
          model_scope || AVP.configuration.default_scope
        end
        avp_scope
      end

      def avp_attribute_serializer(serializer_klass = nil)
        define_singleton_method(:avp_attribute_serializer) do
          return nil if serializer_klass.blank?
          serializer_klass
        end
        avp_attribute_serializer
      end

      def avp_parents(parents = nil)
        define_singleton_method(:avp_parents) do
          parents || nil
        end
        avp_parents
      end

      def avp_identifier(column = nil)
        define_singleton_method(:avp_identifier) do
          column
        end
        avp_identifier
      end

      def avp_type
        "#{avp_scope}::#{avp_name}"
      end

      def parents_schema
        avp_parents&.map { |parent| parent[:class].constantize.avp_type }
      end

      def principal?
        true
      end

      def resource?
        false
      end

      def serialized_schema
        entities = [::AVP::DTO::ModelSchema.to_dto(
          scope: avp_scope, store: avp_store, type: AVP::Enums::EntityType::PRINCIPAL,
          schema: ::AVP::DTO::EntitySchema.to_dto(name: avp_name, attributes: avp_attribute_serializer&.serialize_schema, parents_applicable: parents_schema)
        )]
        if resource?
          AVP_ACTIONS.keys do |action_name|
            entities << AVP::DTO::ModelSchema.to_dto(
              scope: avp_scope, store: avp_store, type: AVP::Enums::EntityType::ACTION,
              schema: AVP::DTO::ActionSchema.to_dto(name: action_name, resources_applicable: avp_type.to_a)
            )
          end
        end
        entities
      end
    end

    def policies
      ::AVP::Principal::Policy.new(principal: to_principal_identifier, store: self.class.avp_store)
    end

    def avp_identifier
      if self.class.avp_identifier.instance_of?(Symbol)
        send(self.class.avp_identifier.to_s)
      elsif self.class.avp_identifier.instance_of?(Proc)
        self.class.avp_identifier.call(self)
      elsif self.class.avp_identifier.instance_of?(String)
        self.class.avp_identifier
      end
    end

    def to_principal_identifier
      ::AVP::DTO::PrincipalIdentifier.to_dto(type: self.class.avp_type, id: avp_identifier)
    end

    def to_entity_definition
      entities = [::AVP::DTO::EntityDefinition.to_dto(identifier: to_principal_identifier, parents: parents_data&.map(&:to_principal_identifier), attributes: self.class.avp_attribute_serializer&.new(self)&.serialize)]
      entities += parents_data&.map(&:to_entity_definition).to_a
      entities.flatten
    end

    def method_missing(method_name, *args, &block)
      # Check if the method name starts with 'can_' and ends with '?'
      if method_name.to_s =~ /^can_(.*?)\?$/
        _action = ::Regexp.last_match(1) # Extract the action (xxx) from the method name
        resource = args.first # Assuming the first argument is a Resource object
        resource.send(method_name.to_s, self)
      else
        # If the method name doesn't match the pattern, raise a NoMethodError
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name.to_s =~ /^can_(.*?)\?$/ || super
    end

    private

    def parents_data
      self.class.avp_parents&.map { |parent| respond_to?(parent[:key].to_sym) ? send(parent[:key].to_sym) : nil }
    end
  end
end
