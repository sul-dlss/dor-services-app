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
      marc_856_records = Marc856Generator.create(@cocina_object, thumbnail_service: @thumbnail_service)

      return if marc_856_records.blank?

      SymphonyWriter.save(marc_856_records)
    end
  end
end
