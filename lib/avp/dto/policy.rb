module AVP
  module DTO
    class Policy
      attr_reader :policy_id

      def initialize(store_id:, policy_id:)
        @store_id = store_id
        @policy_id = policy_id
      end

      def delete
        ::AVP::Connectors::PolicyConnector.new(store_id:).delete(id: policy_id)
      end

      private

      attr_reader :store_id
    end
  end
end
