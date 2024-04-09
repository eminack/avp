require 'avp/models/avp_policy'
require 'aws-sdk-verifiedpermissions'

module AVP
  class Configuration
    attr_accessor :credentials, :default_store, :default_scope, :logger, :policies_map, :sync_schema, :sync_policy

    def initialize
      @credentials = nil
      @default_store = nil
      @default_scope = nil
      @logger = nil
      @sync_schema = true
      @sync_policy = true
      load_policies
    end

    def aws_client
      return @__aws_client if @__aws_client
      if credentials.nil?
        @__aws_client =  ::Aws::VerifiedPermissions::Client.new(logger:)
      else
        @__aws_client = ::Aws::VerifiedPermissions::Client.new(region: credentials[:region], credentials: Aws::Credentials.new(credentials[:aws_access_key], credentials[:aws_secret_access_key]), logger:)
      end
    end

    private

    def load_policies
      if ActiveRecord::Base.connection.table_exists?('avp_policies')
        @policies_map ||= all_policies
      else
        @policies_map = {}
      end
    end

    def all_policies
      AVPPolicy.all.select(:name, :policy_id, :md5).as_json.group_by { |policy| policy['name'] }.transform_values!(&:first)
    end
  end
end
