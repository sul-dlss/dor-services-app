# frozen_string_literal: true

# Look into identityMetadata for compliant ids and use them to fetch
# descriptive metadata from Symphony.  Put the fetched value in the descMetadata
class RefreshMetadataAction
  # @return [NilClass,Object] returns nil if there was no resolvable metadata id.
  # @raises SymphonyReader::ResponseError
  def self.run(identifiers:, datastream:)
    new(identifiers: identifiers, datastream: datastream).run
  end

  # @param [Array<String>] identifiers the set of identifiers that might be resolvable
  # @param [DescMetadataDS] datastream the descriptive metadata
  def initialize(identifiers:, datastream:)
    @identifiers = identifiers
    @datastream = datastream
  end

  # Returns nil if it didn't retrieve anything
  # @raises SymphonyReader::ResponseError
  def run
    content = fetch_datastream
    return nil if content.nil?

    datastream.dsLabel = 'Descriptive Metadata'
    datastream.ng_xml = Nokogiri::XML(content)
    datastream.ng_xml.normalize_text!
    datastream.content = datastream.ng_xml.to_xml
  end

  private

  attr_reader :identifiers, :datastream

  # @raises SymphonyReader::ResponseError
  def fetch_datastream
    metadata_id = MetadataService.resolvable(identifiers).first
    metadata_id.nil? ? nil : MetadataService.fetch(metadata_id.to_s)
  end
end
