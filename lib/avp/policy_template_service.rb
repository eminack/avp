module AVP
  class PolicyTemplateService
    attr_reader :aws_client

    def initialize
      @aws_client = AVP.configuration.aws_client
    end

    def create(store:, description:, policy_stmt:)
      response = aws_client.create_policy_template(
        {
          policy_store_id: store,
          description: description,
          statement: policy_stmt
        }
      )
      response.policy_template_id
    end

    def delete(store:, template_id:)
      aws_client.delete_policy_template(
        {
          policy_store_id: store,
          policy_template_id: template_id
        }
      )
    end
  end
end
