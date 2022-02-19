# frozen_string_literal: true

# Look into identityMetadata for compliant ids and use them to fetch
# descriptive metadata from Symphony.  Put the fetched value in the descMetadata
class RefreshMetadataAction
  include Dry::Monads[:result]

  # @return [Dry::Monads::Result::Failure,Object] returns Failure if there was no resolvable metadata id, otherwise the Cocina object
  # @raises SymphonyReader::ResponseError
  def self.run(identifiers:, cocina_object:)
    new(identifiers: identifiers, cocina_object: cocina_object).run
  end

  # @param [Array<String>] identifiers the set of identifiers that might be resolvable
  # @param [Cocina::Models::DRO|Collection|APO|Agreement] cocina_object to refresh
  def initialize(identifiers:, cocina_object:)
    @identifiers = identifiers
    @cocina_object = cocina_object
  end

  # @return [Dry::Monads::Results,Object] Returns Failure if it didn't retrieve anything, otherwise the Cocicna object
  # @raises SymphonyReader::ResponseError
  def run
    metadata = fetch_metadata
    return Failure() if metadata.nil?

    description_props = Cocina::FromFedora::Descriptive.props(mods: Nokogiri::XML(fetch_metadata), druid: cocina_object.externalIdentifier)
    return Failure() if description_props.nil?

    cocina_object.new(description: description_props)
  end

  private

  attr_reader :identifiers, :cocina_object

  # @raises SymphonyReader::ResponseError
  def fetch_metadata
    metadata_id = MetadataService.resolvable(identifiers).first
    metadata_id.nil? ? nil : MetadataService.fetch(metadata_id.to_s)
  end
end
