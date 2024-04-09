module AVP
  module DTO
    class PrincipalIdentifier
      attr_reader :dto

      def initialize(dto:)
        @dto = dto
      end

      def self.to_dto(type:, id:)
        new(dto: OpenStruct.new(type:, id:))
      end

      def to_json(*_args)
        { entity_type: dto.type, entity_id: dto.id }
      end

      def to_s
        "#{dto.type}::\"#{dto.id}\""
      end
    end
  end
end
