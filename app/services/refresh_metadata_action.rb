# frozen_string_literal: true

# Look into identityMetadata for compliant ids and use them to fetch
# descriptive metadata from Symphony.  Put the fetched value in the descMetadata
class RefreshMetadataAction
  def self.run(object)
    new(object).run(object.descMetadata)
  end

  def initialize(object)
    @object = object
  end

  # Returns nil if it didn't retrieve anything
  def run(datastream)
    content = fetch_datastream
    return nil if content.nil?

    datastream.dsLabel = 'Descriptive Metadata'
    datastream.ng_xml = Nokogiri::XML(content)
    datastream.ng_xml.normalize_text!
    datastream.content = datastream.ng_xml.to_xml
  end

  private

  def fetch_datastream
    candidates = @object.identityMetadata.otherId.collect(&:to_s)
    metadata_id = MetadataService.resolvable(candidates).first
    metadata_id.blank? ? nil : MetadataService.fetch(metadata_id.to_s)
  end
end
