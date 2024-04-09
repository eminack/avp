module AVP
  module DTO
    class ActionSchema
      attr_reader :dto

      def initialize(dto:)
        @dto = dto
      end

      def self.to_dto(name:, resources_applicable:)
        new(dto: OpenStruct.new(name:, resources_applicable:))
      end

      def serialize
        {
          dto.name => {
            'appliesTo' => {
              'resourceTypes' => dto.resources_applicable
            }
          }
        }
      end
    end
  end
end
