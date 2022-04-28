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

      # Requests do not have druids or purls.
      if cocina_object.respond_to?(:externalIdentifier)
        druid = cocina_object.externalIdentifier
        description_class = Cocina::Models::Description
      else
        druid = nil
        description_class = Cocina::Models::RequestDescription
      end

      descriptive_ng_xml = Models::Mapping::ToMods::Description.transform(cocina_object.description, druid)

      # Map MODS back to Cocina.
      title_builder = Models::Mapping::FromMods::TitleBuilderStrategy.find(label: cocina_object.label)
      roundtrip_description_props = Models::Mapping::FromMods::Description.props(title_builder: title_builder, mods: descriptive_ng_xml, druid: druid, label: cocina_object.label)
      roundtrip_description = description_class.new(roundtrip_description_props)

      # Compare original description against roundtripped Cocina.
      # Ignoring identifier since roundtripping is problematic due type mapping.
      unless DeepEqual.match?(roundtrip_description.to_h.except(:identifier), cocina_object.description.to_h.except(:identifier))
        expected = JSON.generate(cocina_object.description.to_h)
        received = JSON.generate(roundtrip_description.to_h)
        return Failure("Roundtripping of descriptive metadata unsuccessful. Expected #{expected} but received #{received}.")
      end

      Success()
    end

    # Validates roundtrip from MODS to Cocina to MODS
    # @param [Fedora::Item, Fedora::AdminPolicy, Fedora::Collection]
    # @return [Dry::Monads::Result]
    def self.valid_from_fedora?(fedora_object)
      title_builder = Cocina::Models::Mapping::FromMods::TitleBuilderStrategy.find(label: fedora_object.label)
      description_props = Cocina::Models::Mapping::FromMods::Description.props(title_builder: title_builder, mods: fedora_object.descMetadata.ng_xml, druid: fedora_object.pid,
                                                                               label: FromFedora::Label.for(fedora_object))
      cocina_description = Cocina::Models::Description.new(description_props)

      roundtrip_mods_ng_xml = Cocina::Models::Mapping::ToMods::Description.transform(cocina_description, fedora_object.pid)

      # Perform approved XML normalization changes to avoid noise in roundtrip failures
      norm_original_ng_xml = Cocina::Models::Mapping::Normalizers::ModsNormalizer.normalize(mods_ng_xml: fedora_object.descMetadata.ng_xml, druid: fedora_object.pid,
                                                                                            label: fedora_object.label)

      unless ModsEquivalentService.equivalent?(norm_original_ng_xml, roundtrip_mods_ng_xml)
        return Failure("Roundtripping of descriptive metadata unsuccessful. Expected #{fedora_object.descMetadata.ng_xml.to_xml} but received #{roundtrip_mods_ng_xml.to_xml}.")
      end

      Success()
    end
  end
end
