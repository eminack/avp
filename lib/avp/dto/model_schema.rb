module AVP
  module DTO
    class ModelSchema
      attr_reader :dto

      def initialize(dto:)
        @dto = dto
      end

      # type = Entity/Action
      def self.to_dto(scope:, store:, type:, schema:)
        new(dto: OpenStruct.new(scope:, store:, type:, schema:))
      end

      def serialize
        dto.schema.serialize
      end
    end
  end
end
