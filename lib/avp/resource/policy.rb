require 'avp/dto/policy_filter'
require 'avp/connectors/policy_connector'

module AVP
  module Resource
    class Policy
      attr_reader :resource, :store

      def initialize(resource:, store:)
        @resource = resource
        @store = store
      end

      def assign(name:, principal:)
        policy_id = AVP.configuration.policies_map[name]['policy_id']
        AVP::Connectors::PolicyConnector.new(store_id: store).assign(template_id: policy_id, resource:, principal: principal&.to_principal_identifier)
      end

      def list(name: nil, principal: nil, max_results: nil)
        policy_id = name.present? ? AVP.configuration.policies_map[name]['policy_id'] : nil
        filters = ::AVP::DTO::PolicyFilter.to_dto(id: policy_id, resource:, principal: principal&.to_principal_identifier, max_results:)
        AVP::Connectors::PolicyConnector.new(store_id: store).list(filters:)
      end
    end
  end
end
