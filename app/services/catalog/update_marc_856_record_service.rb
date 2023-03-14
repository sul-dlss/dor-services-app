# frozen_string_literal: true

module Catalog
  # Creates and writes a MARC 856 stub record based on cocina object.
  class UpdateMarc856RecordService
    def self.update(cocina_object, thumbnail_service:)
      new(cocina_object, thumbnail_service:).update
    end

    def initialize(cocina_object, thumbnail_service:)
      @cocina_object = cocina_object
      @thumbnail_service = thumbnail_service
    end

    def update
      return if cocina_object.admin_policy?

      marc_856_data = Marc856Generator.create(cocina_object, thumbnail_service:, catalog: 'symphony')

      SymphonyWriter.save(cocina_object:, marc_856_data:)
    end

    private

    attr_reader :cocina_object, :thumbnail_service
  end
end
