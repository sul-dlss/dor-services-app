# frozen_string_literal: true

# Look into identityMetadata for compliant ids and use them to fetch
# descriptive metadata from Symphony.  Put the fetched value in the descMetadata
class RefreshMetadataAction
  include Dry::Monads[:result]

  Result = Struct.new('Result', :description_props, :mods_ng_xml)

  # @return [Dry::Monads::Results] returns Failure if there was no resolvable metadata id, otherwise Success (Result with description_props and mods)
  # @raises SymphonyReader::ResponseError
  def self.run(identifiers:, cocina_object:, druid:)
    new(identifiers: identifiers, cocina_object: cocina_object, druid: druid).run
  end

  # @param [Array<String>] identifiers the set of identifiers that might be resolvable
  # @param [Cocina::Models::DRO|Collection|APO|Agreement|RequestDRO|RequestCollection|RequestAPO|RequestAgreement] cocina_object to refresh
  # @param [string] druid
  def initialize(identifiers:, cocina_object:, druid:)
    @identifiers = identifiers
    @cocina_object = cocina_object
    @druid = druid
  end

  # @return [Dry::Monads::Results] Returns Failure if it didn't retrieve anything, otherwise Success (Result with description_props and mods)
  # @raises SymphonyReader::ResponseError
  def run
    return Failure() if mods.nil?

    description_props = Cocina::FromFedora::Descriptive.props(mods: mods_ng_xml, druid: druid)
    return Failure() if description_props.nil?

    Success(Result.new(description_props, mods_ng_xml))
  end

  private

  attr_reader :identifiers, :cocina_object, :druid

  # @raises SymphonyReader::ResponseError
  def mods
    @mods ||= begin
      metadata_id = MetadataService.resolvable(identifiers).first
      metadata_id.nil? ? nil : MetadataService.fetch(metadata_id.to_s)
    end
  end

  def mods_ng_xml
    @mods_ng_xml ||= Nokogiri::XML(mods)
  end
end
