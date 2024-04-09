module AVP
  module Connectors
    class PermissionConnector
      attr_reader :store_id, :client

      def initialize(store_id:)
        @store_id = store_id
        @client = ::AVP.configuration.aws_client
      end

      def authorized?(resource:, principal:, action:)
        authorize_params = {
          policy_store_id: store_id,
          principal: principal.to_principal_identifier.to_json,
          action: action.to_json,
          resource: resource.to_resource_identifier.to_json,
          context: { context_map: {}}, # NOTE: Not considering context variable for now
          entities: { entity_list: resource.to_entity_definition.map(&:to_json) + principal.to_entity_definition.map(&:to_json) }
        }
        response = client.is_authorized(authorize_params)
        if response.errors.present?
          raise response.errors
        else
          response.decision == 'ALLOW'
        end
      end
    end
  end
end
