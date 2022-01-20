# frozen_string_literal: true

module Cocina
  # Validates that descriptive metadata roundtrips.
  class DescriptionRoundtripValidator
    class << self
      include Dry::Monads[:result]
    end

    # Validates roundtrip from Cocina to MODS to Cocina
    # @param [RequestAdminPolicy, RequestDRO, RequestCollection, AdminPolicy, DRO, Collection]
    # @return [Dry::Monads::Result]
    def self.valid_from_cocina?(cocina_object)
      return Success() if cocina_object.description.nil?

      # Requests do not have druids.
      druid = cocina_object.respond_to?(:externalIdentifier) ? cocina_object.externalIdentifier : nil

      descriptive_ng_xml = ToFedora::Descriptive.transform(cocina_object.description, druid).doc
      # Map MODS back to Cocina.
      title_builder = FromFedora::Descriptive::TitleBuilderStrategy.find(label: cocina_object.label)
      roundtrip_description = FromFedora::Descriptive.props(title_builder: title_builder, mods: descriptive_ng_xml, druid: druid)

      # Compare original description against roundtripped Cocina.
      unless DeepEqual.match?(Cocina::Models::Description.new(roundtrip_description).to_h, cocina_object.description.to_h)
        return Failure("Roundtripping of descriptive metadata unsuccessful. Expected #{JSON.generate(cocina_object.description.to_h)} but received #{JSON.generate(roundtrip_description)}.")
      end

      Success()
    end

    # Validates roundtrip from MODS to Cocina to MODS
    # @param [Fedora::Item, Fedora::AdminPolicy, Fedora::Collection]
    # @return [Dry::Monads::Result]
    def self.valid_from_fedora?(fedora_object)
      title_builder = Cocina::FromFedora::Descriptive::TitleBuilderStrategy.find(label: fedora_object.label)
      description_props = Cocina::FromFedora::Descriptive.props(title_builder: title_builder, mods: fedora_object.descMetadata.ng_xml, druid: fedora_object.pid)
      cocina_description = Cocina::Models::Description.new(description_props)

      roundtrip_mods_ng_xml = Cocina::ToFedora::Descriptive.transform(cocina_description, fedora_object.pid).doc

      # Perform approved XML normalization changes to avoid noise in roundtrip failures
      norm_original_ng_xml = Cocina::Normalizers::ModsNormalizer.normalize(mods_ng_xml: fedora_object.descMetadata.ng_xml, druid: fedora_object.pid, label: fedora_object.label)

      unless ModsEquivalentService.equivalent?(norm_original_ng_xml, roundtrip_mods_ng_xml)
        return Failure("Roundtripping of descriptive metadata unsuccessful. Expected #{fedora_object.descMetadata.ng_xml.to_xml} but received #{roundtrip_mods_ng_xml.to_xml}.")
      end

      Success()
    end
  end
end
