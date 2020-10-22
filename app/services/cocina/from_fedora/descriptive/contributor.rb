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

        NAME_PART = {
          'family' => 'surname',
          'given' => 'forename',
          'termsOfAddress' => 'term of address',
          'date' => 'life dates'
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
              contributors << { name: self.class.name_parts(name) }.tap do |contributor_hash|
                contributor_hash[:type] = ROLES.fetch(name['type']) if name['type']
                contributor_hash[:status] = name['usage'] if name['usage']
                roles = [roles_for(name)]
                contributor_hash[:role] = roles unless roles.flatten.empty?
                contributor_hash[:note] = notes_for(name)
                contributor_hash[:identifier] = identifier_for(name)
              end.compact
            end
          end
        end

        # Also used by the Subject class
        def self.name_parts(name, add_default_type: false)
          [].tap do |parts|
            query = name.xpath(NAME_PART_XPATH, mods: DESC_METADATA_NS)
            if query.size == 1
              query.each do |name_part|
                parts << name_part(name_part, add_default_type: add_default_type)
              end
            else
              vals = query.map { |name_part| name_part(name_part, add_default_type: add_default_type) }
              parts << { structuredValue: vals }
            end

            display_form = name.xpath('mods:displayForm', mods: DESC_METADATA_NS).first
            parts << { value: display_form.text, type: 'display' } if display_form
          end
        end

        def self.name_part(name_part_node, add_default_type:)
          { value: name_part_node.content }.tap do |name_part|
            type = if add_default_type
                     NAME_PART.fetch(name_part_node['type'], 'name')
                   elsif name_part_node['type']
                     NAME_PART.fetch(name_part_node['type'])
                   end
            name_part[:type] = type if type
          end
        end

        private

        attr_reader :ng_xml

        def identifier_for(name)
          identifier = name.xpath('mods:nameIdentifier', mods: DESC_METADATA_NS).first
          return unless identifier

          type = 'URI' if URI::DEFAULT_PARSER.make_regexp.match?(identifier.text)
          [{ value: identifier.text, type: type, source: { code: identifier['type'] } }.compact]
        end

        def notes_for(name)
          [].tap do |parts|
            affiliation = name.xpath('mods:affiliation', mods: DESC_METADATA_NS).first
            parts << { value: affiliation.text, type: 'affiliation' } if affiliation

            description = name.xpath('mods:description', mods: DESC_METADATA_NS).first
            parts << { value: description.text, type: 'description' } if description
          end.presence
        end

        def names
          @names ||= ng_xml.xpath(NAME_XPATH, mods: DESC_METADATA_NS)
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
