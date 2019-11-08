# frozen_string_literal: true

# Operations on the legacy Fedora 3 metadata.
# This is used by the accessionWF
class LegacyMetadataService
  # If the updated value is newer than then createDate of the datastream, then update it.
  def self.update_datastream_if_newer(datastream:, updated:, content:)
    datastream.content = content if !datastream.createDate || updated > datastream.createDate
    return if !datastream.createDate || updated > datastream.createDate

    Honeybadger.notify("Found #{datasteam.pid}/#{datastream.dsid} that had a create " \
      "date (#{datastream.createDate}) after the file was modified (#{updated}). " \
      'Doing an experiment to see if this ever happens.')
  end
end
