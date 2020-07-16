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

          # The order of code and val here are important because it's more likely we have a code
          # without a val than vise versa
          if code.present?
            language_hash = { code: code.content,
                              source: {
                                code: code.attribute('authority').value
                              }
                            }
          end

          if val.present?
            language_hash[:value] = val.content
            language_hash[:uri] = val.attribute('valueURI').value
            language_hash[:source][:uri] = val.attribute('authorityURI').value
          end

          langs << language_hash unless language_hash.empty?
        end
      end
    end

    private

    attr_reader :item
  end
end
