# frozen_string_literal: true

module Cocina
  # Maps contributors
  class ContributorMapper
    DESC_METADATA_NS = Dor::DescMetadataDS::MODS_NS

    def self.build(item)
      new(item).build
    end

    def initialize(item)
      @item = item
    end

    def build
      [].tap do |names|
        item.descMetadata.ng_xml.xpath('//mods:name', mods: DESC_METADATA_NS).each do |name|
          name_part = name.xpath('./mods:namePart', mods: DESC_METADATA_NS).first
          role_hash = {}
          name.xpath('./mods:role/mods:roleTerm', mods: DESC_METADATA_NS).each do |role_term|
            if role_term.attribute('type').value.include? 'code'
              role_hash[:code] = role_term.content 
              role_hash[:source] = { code: role_term.attribute('authority').value }
            end
            role_hash[:value] = role_term.content if role_term.attribute('type').value.include? 'text'
          end
          type = name.attribute('type')
          usage = name.attribute('usage')
          name_hash = { name: { value: name_part.content }, type: type.value }
          name_hash[:status] = usage.value if usage.present?
          name_hash[:role] = [role_hash] unless role_hash.empty?
          names << name_hash
        end
      end
    end

    private

    attr_reader :item
  end
end
