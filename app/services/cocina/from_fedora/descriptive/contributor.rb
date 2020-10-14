# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps contributors
      class Contributor
        ROLES = {
          'personal' => 'person',
          'corporate' => 'organization',
          'family' => 'family',
          'conference' => 'conference'
        }.freeze
        NAME_XPATH = '/mods:mods/mods:name'
        NAME_PART_XPATH = './mods:namePart'
        ROLE_CODE_XPATH = './mods:role/mods:roleTerm[@type="code"]'
        ROLE_TEXT_XPATH = './mods:role/mods:roleTerm[@type="text"]'

        # @param [Nokogiri::XML::Document] ng_xml the descriptive metadata XML
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(ng_xml)
          new(ng_xml).build
        end

        def initialize(ng_xml)
          @ng_xml = ng_xml
        end

        def build
          [].tap do |contributors|
            names.each do |name|
              contributors << { name: name_parts(name) }.tap do |contributor_hash|
                contributor_hash[:type] = ROLES.fetch(name['type']) if name['type']
                contributor_hash[:status] = name['usage'] if name['usage']
                roles = [roles_for(name)]
                contributor_hash[:role] = roles unless roles.flatten.empty?
              end
            end
          end
        end

        private

        attr_reader :ng_xml

        def names
          @names ||= ng_xml.xpath(NAME_XPATH, mods: DESC_METADATA_NS)
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
              raise Cocina::Mapper::InvalidDescMetadata, "#{ROLE_CODE_XPATH} is missing required authority attribute" unless role_code['authority']

              role[:code] = role_code.content unless role_code.nil?
              role[:source] = { code: role_code['authority'] }
            end
            role[:value] = role_text.content unless role_text.nil?
          end
        end
      end
    end
  end
end
