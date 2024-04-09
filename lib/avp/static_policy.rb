require 'avp/enums/policy_type'

module AVP
  module StaticPolicy
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def store(store_id = nil)
        define_singleton_method(:store) do
          store_id || ::AVP.configuration.default_store
        end
        store
      end

      def policy_name
        name.demodulize.underscore
      end

      def description(desc = nil)
        define_singleton_method(:description) do
          desc
        end
        description
      end

      def allow(*args)
        define_singleton_method(:allow) do
          args.first
        end
        allow
      end

      def deny(*args)
        define_singleton_method(:deny) do
          args.first
        end
        deny
      end

      def condition(*args)
        define_singleton_method(:condition) do
          args.first
        end
        condition
      end

      def belongs_to(resource_klass = nil)
        define_singleton_method(:belongs_to) do
          resource_klass
        end
        belongs_to
      end

      # this method is used while finding the file path of the classes where policy files are defined
      def template?
        false
      end

      # this method is used while finding the file path of the classes where policy files are defined
      def static?
        true
      end

      def policy_type
        ::AVP::Enums::PolicyType::STATIC
      end

      # TODO: raise proper error if effect is not valid
      def serialized_policy
        raise 'Invalid Effect block' if (allow.present? && deny.present?) || (allow.nil? && deny.nil?)
        effect = allow.present? ? 'permit' : 'forbid'
        args = allow || deny
        "#{effect}(
           principal,
           #{action_string(args[:actions])},
            resource
        ) #{condition_string(condition)};"
      end

      def action_string(actions)
        return ' action' if actions.blank?
        action_dtos = actions.map { |action| belongs_to::AVP_ACTIONS[action.to_sym] }
        values = "[ #{action_dtos.map(&:to_s).join(', ')} ]"
        " action in #{values}"
      end

      # TODO: raise proper error if condition is not valid
      def condition_string(args)
        return '' if args.blank?
        raise 'Invalid Condition in policy ' unless args.keys.size == 1 && (args.keys & [:unless, :when]).size == 1
        effect = args.keys.first
        " #{effect} { #{args[effect.to_sym]} } "
      end
    end
  end
end
