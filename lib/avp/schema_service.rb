require 'avp/enums/entity_type'

module AVP
  class SchemaService
    attr_reader :aws_client

    def initialize
      @aws_client = AVP.configuration.aws_client
    end

    def sync
      return unless AVP.configuration.sync_schema
      models = fetch_models
      # each store will be called separately
      models.group_by { |model| model.dto.store }.each do |store, resources|
        cedar_schema = build_schema(resources)
        sync_schema(store, cedar_schema.to_json)
      end
    end

    private

    def fetch_models
      ObjectSpace.each_object(Class).select do |klass|
        klass.included_modules.include?(AVP::Resource) || klass.included_modules.include?(AVP::Principal)
      end.map(&:serialized_schema).flatten
    end

    def sync_schema(store, schema_json)
      aws_client.put_schema(
        { policy_store_id: store,
          definition: { cedar_json: schema_json }}
      )
    end

    ###
    # Returns
    # {"LabsCoreReloaded":
    #    {
    #     "entityTypes":{
    #       "User":{
    #         "shape":{
    #           "attributes":{
    #             "slug":{"type":"String"},
    #             "datasource":{"type":"String"},
    #             "properties":{"type":"Record",
    #                           "attributes":{
    #                               "name":{"type":"String"},
    #                               "age":{"type":"Long"}}},
    #                            },
    #                          }
    #             }
    #           "type":"Record"
    #         },
    #         "memberOfTypes":["LabsCoreReloaded::Organization"]
    #       }
    #     },
    #     "actions":{
    #       "create_list_company":{
    #         "appliesTo":{
    #           "resourceTypes":["LabsCoreReloaded::ListCompanies"]
    #         }
    #       },
    #       "update_list_company":{
    #         "appliesTo":{
    #           "resourceTypes":["LabsCoreReloaded::ListCompanies"]
    #         }
    #       }
    #     }
    # },
    # "RailsBackendServer":{
    #     "entityTypes":{
    #         "List":{
    #           "shape":{
    #             "attributes":{},
    #             "type":"Record"
    #           },
    #         "memberOfTypes":[]
    #         }
    #      },
    #     "actions":{
    #         "create_list":{
    #           "appliesTo":{
    #             "resourceTypes":["RailsBackendServer::List"]
    #            }
    #         }
    #     }
    #  }
    def build_schema(resources)
      schema_json = {}
      resources.group_by { |resource| resource.dto.scope }.each do |scope, scoped_resources|
        entities = scoped_resources.select { |res| res.dto.type == ::AVP::Enums::EntityType::RESOURCE || res.dto.type == ::AVP::Enums::EntityType::PRINCIPAL }.map(&:serialize).reduce({}, :merge)
        actions = scoped_resources.select { |res| res.dto.type == ::AVP::Enums::EntityType::ACTION }.map(&:serialize).reduce({}, :merge)
        schema_json[scope] = { entityTypes: entities, actions: actions}
      end
      schema_json
    end
  end
end
