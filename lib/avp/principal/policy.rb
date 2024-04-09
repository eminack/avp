require 'avp/dto/policy_filter'
require 'avp/connectors/policy_connector'

module AVP
  module Principal
    class Policy
      attr_reader :principal, :store

      def initialize(principal:, store:)
        @principal = principal
        @store = store
      end

      def assign(name:, resource:)
        policy_id = AVP.configuration.policies_map[name]['policy_id']
        AVP::Connectors::PolicyConnector.new(store_id: store).assign(template_id: policy_id, resource: resource.to_resource_identifier, principal:)
      end

      def list(name: nil, resource: nil, max_results: nil)
        policy_id = name.present? ? AVP.configuration.policies_map[name]['policy_id'] : nil
        filters = ::AVP::DTO::PolicyFilter.to_dto(id: policy_id, resource: resource&.to_resource_identifier, principal:, max_results:)
        AVP::Connectors::PolicyConnector.new(store_id: store).list(filters:)
      end
    end
  end
end
