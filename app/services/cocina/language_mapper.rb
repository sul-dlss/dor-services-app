# frozen_string_literal: true

module Cocina
  # Maps languages
  class LanguageMapper
    DESC_METADATA_NS = Dor::DescMetadataDS::MODS_NS

    def self.build(item)
      new(item).build
    end

    def initialize(item)
      @item = item
    end

    def build
      [].tap do |langs|
        item.descMetadata.ng_xml.xpath('//mods:language', mods: DESC_METADATA_NS).each do |lang|
          language_hash = {}
          val = lang.xpath('./mods:languageTerm[@type="text"]', mods: DESC_METADATA_NS).first
          code = lang.xpath('./mods:languageTerm[@type="code"]', mods: DESC_METADATA_NS).first

          language_hash = {
            value: val.content,
            uri: val.attribute('valueURI').value,
            source: {
              uri: val.attribute('authorityURI').value
            }
          } if val.present?

          language_hash = {
            code: code.content,
            source: {
              code: code.attribute('authority').value
            }
          } if code.present?

          langs << language_hash unless language_hash.empty?
        end
      end
    end

    private

    attr_reader :item
  end
end
