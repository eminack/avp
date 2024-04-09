module AVP
  module DTO
    class EntitySchema
      attr_reader :dto

      def initialize(dto:)
        @dto = dto
      end

      def self.to_dto(name:, attributes:, parents_applicable:)
        new(dto: OpenStruct.new(name:, attributes: attributes || {}, parents_applicable: parents_applicable || []))
      end

      def serialize
        {
          dto.name => {
            'shape' => {
              'attributes' => dto.attributes,
              'type' => 'Record'
            },
            'memberOfTypes' => dto.parents_applicable
          }
        }
      end
    end
  end
end
