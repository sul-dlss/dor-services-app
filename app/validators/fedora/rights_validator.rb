# frozen_string_literal: true

module Fedora
  # Validator for Rights datastream.
  class RightsValidator
    include Dry::Monads[:result]

    # @param [Nokogiri::Document] ng_xml
    # @return [Dry::Monads::Result]
    def self.valid?(ng_xml)
      new(ng_xml).valid?
    end

    def initialize(ng_xml)
      @ng_xml = ng_xml
    end

    def valid?
      dra = Dor::RightsMetadataDS.from_xml(ng_xml.to_xml).dra_object
      return Failure([dra.index_elements[:errors].to_sentence]) if dra.index_elements[:errors].present?

      Success()
    end

    private

    attr_reader :ng_xml
  end
end
