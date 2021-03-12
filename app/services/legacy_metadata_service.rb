# frozen_string_literal: true

# Operations on the legacy Fedora 3 metadata.
# This is used by the accessionWF and the etdSubmitWF
class LegacyMetadataService
  # Error indicating a validation error with the datastream.
  class DatastreamValidationError < StandardError
    def initialize(message, detail: nil)
      super(message)
      @detail = detail
    end

    attr_reader :detail
  end

  # If the updated value is newer than then createDate of the datastream, then update it.
  # @raise [DatastreamValidationError] if datastream fails validation
  def self.update_datastream_if_newer(datastream:, updated:, content:, event_factory:)
    new(datastream: datastream, updated: updated, content: content, event_factory: event_factory).update_datastream_if_newer
  end

  def initialize(datastream:, updated:, content:, event_factory:)
    @datastream = datastream
    @updated = updated
    @content = content
    @event_factory = event_factory
  end

  def update_datastream_if_newer
    if !datastream.createDate || updated > datastream.createDate
      datastream.content = content
      event_factory.create(druid: datastream.pid, event_type: 'legacy_metadata_update', data: { datastream: datastream.dsid })
    end

    validate_desc_metadata if datastream.dsid == 'descMetadata'
    validate_rights_metadata if datastream.dsid == 'rightsMetadata'

    return if !datastream.createDate || updated > datastream.createDate

    Honeybadger.notify("Found #{datastream.pid}/#{datastream.dsid} that had a create " \
      "date (#{datastream.createDate}) after the file was modified (#{updated}). " \
      'Doing an experiment to see if this ever happens.')
  end

  private

  attr_reader :datastream, :updated, :content, :event_factory

  def validate_rights_metadata
    result = Fedora::RightsValidator.valid?(datastream.ng_xml)
    raise DatastreamValidationError.new('Invalid rightsMetadata', detail: result.failure.join(' ')) if result.failure?
  end

  def validate_desc_metadata
    result = ModsValidator.valid?(datastream.ng_xml)
    raise DatastreamValidationError.new('MODS validation failed', detail: result.failure.join(' ')) if result.failure?

    raise DatastreamValidationError, "#{datastream.pid} descMetadata missing required fields (<title>)" if datastream.mods_title.blank?
  end
end
