module AVP
  module DTO
    class EntityDefinition
      attr_reader :dto

      def initialize(dto:)
        @dto = dto
      end

      def self.to_dto(identifier:, parents:, attributes:)
        new(dto: OpenStruct.new(identifier:, parents: parents || [], attributes: attributes || {}))
      end

      def to_json(*_args)
        {
          identifier: dto.identifier.to_json,
          parents: dto.parents.map(&:to_json),
          attributes: dto.attributes
        }
      end
    end
  end
end
