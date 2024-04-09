module AVP
  module DTO
    class PolicyFilter
      attr_reader :dto

      def initialize(dto:)
        @dto = dto
      end

      def self.to_dto(id:, resource:, principal:, max_results:)
        new(dto: OpenStruct.new(id:, resource:, principal:, max_results:))
      end
    end
  end
end
