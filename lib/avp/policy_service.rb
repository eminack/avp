require 'digest/md5'
require 'avp/enums/policy_type'

module AVP
  class PolicyService
    def sync
      return unless AVP.configuration.sync_policy
      global_policy_map = AVP.configuration.policies_map
      klasses = fetch_policy_klasses
      found_policies = []
      klasses.each do |klass|
        md5 = Digest::MD5.hexdigest(klass.serialized_policy)
        policy_name = klass.policy_name
        found_policies << policy_name

        if global_policy_map[policy_name].present? && global_policy_map[policy_name]['md5'] == md5
          # policy already exists in AVPS
          next
        elsif global_policy_map[policy_name].present? && global_policy_map[policy_name]['md5'] != md5
          # policy is updated
          raise 'Policy cannot be updated'
        elsif global_policy_map[policy_name].blank?
          # puts "Creating policy #{policy_name}, #{klass.description}, #{klass.serialized_policy} #{klass.store}"
          policy_id = create(klass)
          AVPPolicy.where(name: policy_name, policy_type: klass.policy_type).first_or_create.update!(policy_id: policy_id, md5: md5, store_id: klass.store)
        end
      end
      # delete policies that are not found in the code
      AVPPolicy.where.not(name: found_policies).map { |policy| delete(policy) }
    end

    private

    def delete(policy)
      if policy.policy_type == ::AVP::Enums::PolicyType::TEMPLATE
        AVP::PolicyTemplateService.new.delete(store: policy.store_id, template_id: policy.policy_id)
      elsif policy.policy_type == ::AVP::Enums::PolicyType::STATIC
        AVP::StaticPolicyService.new.delete(store: policy.store_id, policy_id: policy.policy_id)
      end
      policy.destroy
    end

    def create(klass)
      if klass.template?
        policy_id = AVP::PolicyTemplateService.new.create(store: klass.store, description: klass.description, policy_stmt: klass.serialized_policy)
      elsif klass.static?
        policy_id = AVP::StaticPolicyService.new.create(store: klass.store, description: klass.description, policy_stmt: klass.serialized_policy)
      end
      policy_id
    end

    def fetch_policy_klasses
      ObjectSpace.each_object(Class).select do |klass|
        klass.included_modules.include?(AVP::PolicyTemplate) || klass.included_modules.include?(AVP::StaticPolicy)
      end
    end
  end
end
