# frozen_string_literal: true

# Creates and writes a MARC record based on cocina object.
class UpdateMarcRecordService
  def self.update(cocina_object, thumbnail_service:)
    new(cocina_object, thumbnail_service:).update
  end

  def initialize(cocina_object, thumbnail_service:)
    @cocina_object = cocina_object
    @thumbnail_service = thumbnail_service
  end

  def update
    marc_records = MarcGenerator.create(@cocina_object, thumbnail_service: @thumbnail_service)

    return if marc_records.blank?

    SymphonyWriter.save(marc_records)
  end
end
