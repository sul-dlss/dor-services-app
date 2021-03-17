# frozen_string_literal: true

# Look into identityMetadata for compliant ids and use them to fetch
# descriptive metadata from Symphony.  Put the fetched value in the descMetadata
class RefreshMetadataAction
  # @return [NilClass,Object] returns nil if there was no resolvable metadata id.
  # @raises SymphonyReader::ResponseError
  def self.run(identifiers:, fedora_object:)
    new(identifiers: identifiers, fedora_object: fedora_object).run
  end

  # @param [Array<String>] identifiers the set of identifiers that might be resolvable
  # @param [Dor::Abstract] fedora_object to refresh
  def initialize(identifiers:, fedora_object:)
    @identifiers = identifiers
    @fedora_object = fedora_object
    @datastream = fedora_object.descMetadata
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

    validate

    datastream
  end

  private

  attr_reader :identifiers, :datastream, :fedora_object

  # @raises SymphonyReader::ResponseError
  def fetch_datastream
    metadata_id = MetadataService.resolvable(identifiers).first
    metadata_id.nil? ? nil : MetadataService.fetch(metadata_id.to_s)
  end

  def validate
    return unless Settings.enabled_features.validate_descriptive_roundtrip.refresh

    result = Cocina::DescriptionRoundtripValidator.valid_from_fedora?(fedora_object)
    Honeybadger.notify('DescMetadata did not successfully roundtrip after metadata refresh.') if result.failure?
  end
end
