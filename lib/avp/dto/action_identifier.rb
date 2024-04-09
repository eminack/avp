module AVP
  module DTO
    class ActionIdentifier
      attr_reader :dto

      def initialize(dto:)
        @dto = dto
      end

      def self.to_dto(type:, id:)
        new(dto: OpenStruct.new(type:, id:))
      end

      def to_json(*_args)
        { action_type: "#{dto.type}::Action", action_id: dto.id }
      end

      def to_s
        "#{dto.type}::Action::\"#{dto.id}\""
      end
    end
  end
end
