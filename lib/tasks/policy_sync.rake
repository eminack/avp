require 'avp/policy_service'

namespace :avp do
  task policy_sync: :environment do
    Rails.application.eager_load!
    ::AVP::PolicyService.new.sync
  end
end
