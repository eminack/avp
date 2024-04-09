require 'avp/schema_service'

namespace :avp do
  task schema_sync: :environment do
    Rails.application.eager_load!
    ::AVP::SchemaService.new.sync
  end
end
