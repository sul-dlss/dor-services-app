# frozen_string_literal: true

module Cocina
  module FromFedora
    # Maps contributors
    class ContributorMapper
      DESC_METADATA_NS = Dor::DescMetadataDS::MODS_NS
      NAME_XPATH = '/mods:mods/mods:name'
      NAME_PART_XPATH = './mods:namePart'
      ROLE_CODE_XPATH = './mods:role/mods:roleTerm[@type="code"]'
      ROLE_TEXT_XPATH = './mods:role/mods:roleTerm[@type="text"]'

      def self.build(item)
        new(item).build
      end

      def initialize(item)
        @item = item
      end

      def build
        [].tap do |contributors|
          names.each do |name|
            contributors << { name: name_parts(name) }.tap do |contributor_hash|
              contributor_hash[:type] = name.attribute('type').value if name.attribute('type').present?
              contributor_hash[:status] = name.attribute('usage').value if name.attribute('usage').present?
              roles = [roles_for(name)]
              contributor_hash[:role] = roles unless roles.flatten.empty?
            end
          end
        end
      end

      private

      attr_reader :item

      def names
        @names ||= item.descMetadata.ng_xml.xpath(NAME_XPATH, mods: DESC_METADATA_NS)
      end

      def name_parts(name)
        [].tap do |parts|
          name.xpath(NAME_PART_XPATH, mods: DESC_METADATA_NS).each do |name_part|
            parts << { value: name_part.content }
          end
        end
      end

      def roles_for(name)
        role_code = name.xpath(ROLE_CODE_XPATH, mods: DESC_METADATA_NS).first
        role_text = name.xpath(ROLE_TEXT_XPATH, mods: DESC_METADATA_NS).first
        return [] if role_code.nil? && role_text.nil?

        {}.tap do |role|
          if role_code.present?
            role[:code] = role_code.content unless role_code.nil?
            role[:source] = { code: role_code.attribute('authority').value }
          end
          role[:value] = role_text.content unless role_text.nil?
        end
      end
    end
  end
end
