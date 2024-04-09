require 'avp/dto/policy'

module AVP
  module Connectors
    class PolicyConnector
      attr_reader :store_id, :client

      MAX_ALLOWED_RESULTS = 50

      def initialize(store_id:)
        @store_id = store_id
        @client = AVP.configuration.aws_client
      end

      def assign(template_id:, resource:, principal:)
        definition = { policy_store_id: store_id,
                       definition: { template_linked: { policy_template_id: template_id, principal: principal&.to_json, resource: resource&.to_json }.compact }}
        client.create_policy(definition)
      end

      def delete(id:)
        client.delete_policy({ policy_store_id: store_id, policy_id: id })
      end

      def list(filters:)
        policies = []
        result = client.list_policies(list_params(filters, nil, filters.dto.max_results))
        policies += result.policies

        while result.next_token
          break if filters.dto.max_results.present? && policies.size > filters.dto.max_results
          remaining_count = filters.dto.max_results.present? ? filters.dto.max_results - policies.size : nil
          result = client.list_policies(list_params(filters, result.next_token, remaining_count))
          policies += result.policies
        end
        policies.map(&:policy_store_id)
        policies.map { |policy| AVP::DTO::Policy.new(store_id:, policy_id: policy.policy_id) }
      end

      private

      def list_params(filters, next_token = nil, max_results = nil)
        {
          policy_store_id: store_id,
          next_token:,
          max_results: max_results || MAX_ALLOWED_RESULTS,
          filter: {
            principal: { identifier: filters.dto.principal&.to_json }.compact,
            resource: { identifier: filters.dto.resource&.to_json }.compact,
            policy_type: 'TEMPLATE_LINKED',
            policy_template_id: filters.dto.id
          }.compact.reject { |_, value| value == {} }
        }.compact.reject { |_, value| value == {} }
      end
    end
  end
end
