# frozen_string_literal: true

# Fetch descriptive metadata from catalog and update description.
class RefreshDescriptionFromCatalog
  include Dry::Monads[:result]

  Result = Struct.new('Result', :description_props, :mods_ng_xml)

  # @param [Cocina::Models::DRO|Collection|APO|Agreement|RequestDRO|RequestCollection|RequestAPO|RequestAgreement] cocina_object to refresh #rubocop:disable Layout/LineLength
  # @param [string] druid
  # @return [Dry::Monads::Results] returns Failure if there was no refreshable catalog link or barcode, otherwise
  # Success (Result with description_props and mods)
  def self.run(cocina_object:, druid:, use_barcode: false)
    new(cocina_object:, druid:, use_barcode:).run
  end

  def initialize(cocina_object:, druid:, use_barcode:)
    @cocina_object = cocina_object
    @druid = druid
    @use_barcode = use_barcode
  end

  # @return [Dry::Monads::Results] Returns Failure if description unchanged (e.g., no refreshable identifiers),
  # otherwise Success (Result with description_props and mods)
  # @raises Catalog::MarcService::MarcServiceError
  def run # rubocop:disable Metrics/AbcSize
    # Admin policies don't have identification.
    return Failure() if cocina_object.admin_policy?
    # No identifiers to refresh from.
    return Failure() unless identifiers.any?

    return Failure() if marc_service.mods.nil?

    description_props = Cocina::Models::Mapping::FromMods::Description.props(mods: marc_service.mods_ng, druid:,
                                                                             label: cocina_object.label)
    return Failure() if description_props.nil?

    Success(Result.new(description_props, marc_service.mods_ng))
  end

  private

  attr_reader :cocina_object, :druid, :use_barcode

  # @raises Catalog::MarcService::MarcServiceError
  def marc_service
    @marc_service ||= Catalog::MarcService.new(**identifiers)
  end

  def identifiers
    {
      folio_instance_hrid:,
      barcode:
    }.compact
  end

  def folio_instance_hrid
    Array(cocina_object.identification&.catalogLinks).find do |link|
      link.catalog == 'folio' && link.refresh
    end&.catalogRecordId
  end

  def barcode
    return nil unless use_barcode

    cocina_object.identification.try(:barcode)
  end
end
