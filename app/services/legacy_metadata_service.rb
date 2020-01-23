# frozen_string_literal: true

# Operations on the legacy Fedora 3 metadata.
# This is used by the accessionWF
class LegacyMetadataService
  # If the updated value is newer than then createDate of the datastream, then update it.
  def self.update_datastream_if_newer(datastream:, updated:, content:, event_factory:)
    if !datastream.createDate || updated > datastream.createDate
      datastream.content = content
      event_factory.create(druid: datastream.pid, event_type: 'legacy_metadata_update', data: { datastream: datastream, host: Socket.gethostname })
    end

    validate_desc_metadata(datastream) if datastream.dsid == 'descMetadata'

    return if !datastream.createDate || updated > datastream.createDate

    Honeybadger.notify("Found #{datastream.pid}/#{datastream.dsid} that had a create " \
      "date (#{datastream.createDate}) after the file was modified (#{updated}). " \
      'Doing an experiment to see if this ever happens.')
  end

  def self.validate_desc_metadata(datastream)
    raise "#{datastream.pid} descMetadata missing required fields (<title>)" if datastream.mods_title.blank?
  end
  private_class_method :validate_desc_metadata
end
