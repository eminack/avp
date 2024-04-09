require 'avp/resource/policy'
require 'avp/dto/action_identifier'
require 'avp/dto/resource_identifier'
require 'avp/connectors/permission_connector'
require 'avp/dto/entity_definition'
require 'avp/dto/model_schema'
require 'avp/dto/entity_schema'
require 'avp/dto/action_schema'
require 'avp/enums/entity_type'

module AVP
  module Resource
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
        avp_parents(args[:parents])
        avp_actions(args[:actions])
        avp_identifier(args[:identifier])
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

      def avp_identifier(column = nil)
        define_singleton_method(:avp_identifier) do
          column
        end
        avp_identifier
      end

      def avp_parents(parents = nil)
        define_singleton_method(:avp_parents) do
          parents || nil
        end
        avp_parents
      end

      def avp_type
        "#{avp_scope}::#{avp_name}"
      end

      def parents_schema
        avp_parents&.map { |parent| parent[:class].constantize.avp_type }
      end

      def principal?
        false
      end

      def resource?
        true
      end

      def avp_actions(input)
        action_hash = {}
        input.map { |action_name| action_hash[action_name] = ::AVP::DTO::ActionIdentifier.to_dto(type: avp_scope.to_s, id: action_name.to_s) }
        const_set('AVP_ACTIONS', action_hash)

        input.each do |action_name|
          define_method "can_#{action_name}?" do |principal|
            ::AVP::Connectors::PermissionConnector.new(store_id: self.class.avp_store).authorized?(principal:, resource: self, action: self.class::AVP_ACTIONS[action_name])
          end
        end
      end

      def serialized_schema
        entities = [::AVP::DTO::ModelSchema.to_dto(
          scope: avp_scope, store: avp_store, type: ::AVP::Enums::EntityType::RESOURCE,
          schema: ::AVP::DTO::EntitySchema.to_dto(name: avp_name, attributes: avp_attribute_serializer&.serialize_schema, parents_applicable: parents_schema)
        )]
        if resource?
          self::AVP_ACTIONS.each_key do |action_name|
            entities << AVP::DTO::ModelSchema.to_dto(
              scope: avp_scope, store: avp_store, type: ::AVP::Enums::EntityType::ACTION,
              schema: AVP::DTO::ActionSchema.to_dto(name: action_name.to_s, resources_applicable: Array.wrap(avp_type))
            )
          end
        end
        entities
      end
    end

    def policies
      ::AVP::Resource::Policy.new(resource: to_resource_identifier, store: self.class.avp_store)
    end

    def to_resource_identifier
      ::AVP::DTO::ResourceIdentifier.to_dto(type: self.class.avp_type, id: avp_identifier)
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

    def to_entity_definition
      entities = [::AVP::DTO::EntityDefinition.to_dto(identifier: to_resource_identifier, parents: parents_data&.map(&:to_principal_identifier), attributes: self.class.avp_attribute_serializer&.new(self)&.serialize)]
      entities += parents_data&.map(&:to_entity_definition).to_a
      entities.flatten
    end

    private

    def avp_type
      "#{self.class.avp_scope}::#{self.class.avp_name}"
    end

    def parents_data
      self.class.avp_parents&.map { |parent| send(parent[:key].to_s) }
    end
  end
end
