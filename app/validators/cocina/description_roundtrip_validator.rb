# frozen_string_literal: true

module Cocina
  # Validates that descriptive metadata roundtrips.
  class DescriptionRoundtripValidator
    # @param [RequestAdminPolicy, RequestDRO, RequestCollection, AdminPolicy, DRO, Collection]
    def initialize(cocina_object)
      @cocina_object = cocina_object
    end

    attr_reader :error

    def valid?
      return true if cocina_object.description.nil?

      descriptive_ng_xml = ToFedora::Descriptive.transform(cocina_object.description, druid).doc
      # Map MODS back to Cocina.
      title_builder = FromFedora::Descriptive::TitleBuilderStrategy.find(label: cocina_object.label)
      roundtrip_description = FromFedora::Descriptive.props(title_builder: title_builder, mods: descriptive_ng_xml, druid: druid)

      # Compare original description against roundtripped Cocina.
      unless DeepEqual.match?(roundtrip_description, cocina_object.description.to_h)
        @error = "Roundtripping of descriptive metadata unsuccessful. Expected #{cocina_object.description.to_h} but received #{roundtrip_description}."
        return false
      end

      true
    end

    private

    attr_reader :cocina_object

    def druid
      # Requests do not have druids.
      @druid ||= cocina_object.respond_to?(:externalIdentifier) ? cocina_object.externalIdentifier : nil
    end
  end
end
