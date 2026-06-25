# frozen_string_literal: true

# Fetch descriptive metadata from catalog and update description.
class RefreshDescriptionFromCatalog
  include Dry::Monads[:result]

  Result = Struct.new('Result', :description_props)

  # @see #run, #initialize
  def self.run(...)
    new(...).run
  end

  # @param cocina_object [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::APO, Cocina::Models::Agreement,
  #   Cocina::Models::RequestDRO, Cocina::Models::RequestCollection, Cocina::Models::RequestAPO,
  #   Cocina::Models::RequestAgreement] cocina object to refresh
  # @param druid [String] the druid identifier
  # @param use_barcode [Boolean] whether to use barcode as an identifier (default: false)
  # @param create_marc_if_missing [Boolean] whether to create a MARC record if missing in the catalog (default: false)
  def initialize(cocina_object:, druid:, use_barcode: false, create_marc_if_missing: false)
    @cocina_object = cocina_object
    @druid = druid
    @use_barcode = use_barcode
    @create_marc_if_missing = create_marc_if_missing
  end

  # @return [Dry::Monads::Results] Returns Failure if description unchanged (e.g., no refreshable identifiers),
  #   otherwise Success (Result with description_props)
  # @raise [Catalog::MarcService::Error]
  def run
    # Admin policies don't have identification.
    return Failure() if cocina_object.admin_policy?
    return Failure() unless refreshable?

    marc_hash = marc_service.marc
    return Failure() if marc_hash.nil?

    marc = MARC::Record.new_from_hash(marc_hash)

    description_props = Cocina::FromMarc::Description.props(marc:, druid:)

    return Failure() if description_props.nil?

    Success(Result.new(description_props))
  end

  private

  attr_reader :cocina_object, :druid, :use_barcode, :create_marc_if_missing

  # @raises Catalog::MarcService::Error
  def marc_service
    @marc_service ||= Catalog::MarcService.new(**identifiers, create_marc_if_missing:)
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

  def refreshable?
    # Requires an identifier but if any catalog links exist that are set to refresh: false, do not refresh
    identifiers.any? && Array(cocina_object.identification&.catalogLinks).find do |link|
      link.catalog == 'folio' && !link.refresh
    end.blank?
  end
end
