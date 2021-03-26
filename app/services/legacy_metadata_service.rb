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
  def self.update_datastream_if_newer(item:, datastream_name:, updated:, content:, event_factory:)
    new(item: item, datastream_name: datastream_name, updated: updated, content: content, event_factory: event_factory).update_datastream_if_newer
  end

  def initialize(item:, datastream_name:, updated:, content:, event_factory:)
    @item = item
    @datastream = item.datastreams[datastream_name]
    @updated = updated
    @content = content
    @event_factory = event_factory
  end

  # rubocop:disable Metrics/AbcSize
  def update_datastream_if_newer
    if !datastream.createDate || updated > datastream.createDate
      datastream.content = content
      event_factory.create(druid: datastream.pid, event_type: 'legacy_metadata_update', data: { datastream: datastream.dsid })
    end

    validate_desc_metadata if datastream.dsid == 'descMetadata'
    validate_rights_metadata if datastream.dsid == 'rightsMetadata'

    return if !datastream.createDate || updated > datastream.createDate

    # do not send alerts to HB for Hydrus items (see https://github.com/sul-dlss/dor-services-app/issues/2478)
    return if AdministrativeTags.project(pid: @item.id).include?('Hydrus')

    Honeybadger.notify("Found #{datastream.pid}/#{datastream.dsid} that had a create " \
      "date (#{datastream.createDate}) after the file was modified (#{updated}). " \
      'Doing an experiment to see if this ever happens.')
  end
  # rubocop:enable Metrics/AbcSize

  private

  attr_reader :datastream, :updated, :content, :event_factory, :item

  def validate_rights_metadata
    result = Fedora::RightsValidator.valid?(datastream.ng_xml)
    raise DatastreamValidationError.new('Invalid rightsMetadata', detail: result.failure.join(' ')) if result.failure?
  end

  def validate_desc_metadata
    result = ModsValidator.valid?(datastream.ng_xml)
    raise DatastreamValidationError.new('MODS validation failed', detail: result.failure.join(' ')) if result.failure?

    if Settings.enabled_features.validate_descriptive_roundtrip.legacy
      result = Cocina::DescriptionRoundtripValidator.valid_from_fedora?(item)
      raise DatastreamValidationError.new('MODS roundtripping failed', detail: result.failure) unless result.success?
    end

    raise DatastreamValidationError, "#{datastream.pid} descMetadata missing required fields (<title>)" if datastream.mods_title.blank?
  end
end
