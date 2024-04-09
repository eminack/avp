module AVP
  class StaticPolicyService
    attr_reader :aws_client

    def initialize
      @aws_client = AVP.configuration.aws_client
    end

    def create(store:, description:, policy_stmt:)
      response = aws_client.create_policy(
        {
          policy_store_id: store,
          definition: {
            static: {
              description:,
              statement: policy_stmt
            }
          }
        }
      )
      response.policy_id
    end

    def delete(store:, policy_id:)
      aws_client.delete_policy(
        {
          policy_store_id: store,
          policy_id:
        }
      )
    end
  end
end
