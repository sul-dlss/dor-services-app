# frozen_string_literal: true

# Use resolvable identifiers to fetch descriptive metadata from Symphony.
class RefreshMetadataAction
  include Dry::Monads[:result]

  Result = Struct.new('Result', :description_props, :mods_ng_xml)

  # @return [Dry::Monads::Results] returns Failure if there was no resolvable metadata id, otherwise Success (Result with description_props and mods)
  # @raise Catalog::MarcService::MarcServiceError
  def self.run(identifiers:, cocina_object:, druid:)
    new(identifiers:, cocina_object:, druid:).run
  end

  # @param [Cocina::Models::DRO|Collection|APO|Agreement|RequestDRO|RequestCollection|RequestAPO|RequestAgreement] cocina_object
  # @return [Array] Refreshable identifiers in the object
  def self.identifiers(cocina_object:)
    cocina_object.identification.catalogLinks.filter_map { |clink| "catkey:#{clink.catalogRecordId}" if clink.catalog == 'symphony' && clink.refresh }
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
  # @raise Catalog::MarcService::MarcServiceError
  def run
    return Failure() if mods.nil?

    description_props = Cocina::Models::Mapping::FromMods::Description.props(mods: mods_ng_xml, druid:, label: cocina_object.label)
    return Failure() if description_props.nil?

    Success(Result.new(description_props, mods_ng_xml))
  end

  private

  attr_reader :identifiers, :cocina_object, :druid

  # @raise Catalog::MarcService::MarcServiceError
  def mods
    @mods ||= begin
      metadata_id = ModsService.resolvable(identifiers).first
      metadata_id.nil? ? nil : ModsService.fetch(metadata_id.to_s)
    end
  end

  def mods_ng_xml
    @mods_ng_xml ||= Nokogiri::XML(mods)
  end
end
