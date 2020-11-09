# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
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
              Honeybadger.notify('[DATA ERROR] name type attribute is set to ""', { tags: 'data_error' }) if name['type'] == ''

              contributors << build_contributor_hash(name).reject { |_k, v| v.blank? } # name: can be an empty array, so can't use .compact
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
              vals = query.map { |name_part| name_part(name_part, add_default_type: add_default_type) }.compact
              parts << { structuredValue: vals }
            end

            display_form = name.xpath('mods:displayForm', mods: DESC_METADATA_NS).first
            parts << { value: display_form.text, type: 'display' } if display_form
          end.compact
        end

        def self.name_part(name_part_node, add_default_type:)
          if name_part_node.content.blank?
            Honeybadger.notify('[DATA ERROR] name/namePart missing value', { tags: 'data_error' })
            return
          end

          { value: name_part_node.content }.tap do |name_part|
            Honeybadger.notify('[DATA ERROR] name/namePart type attribute set to ""', { tags: 'data_error' }) if name_part_node['type'] == ''

            type = if add_default_type
                     NAME_PART.fetch(name_part_node['type'], 'name')
                   elsif NAME_PART.key? name_part_node['type']
                     NAME_PART.fetch(name_part_node['type'])
                   elsif name_part_node['type'].present?
                     Honeybadger.notify("[DATA ERROR] namePart has unknown type assigned to it: '#{name_part_node['type']}'", { tags: 'data_error' })
                   end
            name_part[:type] = type if type
          end
        end

        private

        attr_reader :ng_xml

        def build_contributor_hash(name)
          { name: self.class.name_parts(name) }.tap do |contributor_hash|
            contributor_hash[:type] = type_for(name['type']) if name['type'].present?
            contributor_hash[:status] = name['usage'] if name['usage']
            roles = [roles_for(name)]
            contributor_hash[:role] = roles unless roles.flatten.empty? || contributor_hash[:name].blank?
            contributor_hash[:note] = notes_for(name)
            contributor_hash[:identifier] = identifier_for(name)
          end
        end

        def identifier_for(name)
          identifier = name.xpath('mods:nameIdentifier', mods: DESC_METADATA_NS).first
          return unless identifier

          identifier_type = identifier['type']
          source = { code: identifier_type } if identifier_type
          type = 'URI' if URI::DEFAULT_PARSER.make_regexp.match?(identifier.text)
          [{ value: identifier.text, type: type, source: source }.compact]
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

        ROLE_CODE_XPATH = './mods:role/mods:roleTerm[@type="code"]'
        ROLE_TEXT_XPATH = './mods:role/mods:roleTerm[@type="text"]'
        ROLE_AUTHORITY_XPATH = './mods:role/mods:roleTerm/@authority'
        ROLE_AUTHORITY_URI_XPATH = './mods:role/mods:roleTerm/@authorityURI'
        ROLE_AUTHORITY_VALUE_XPATH = './mods:role/mods:roleTerm/@valueURI'

        # rubocop:disable Metrics/AbcSize
        def roles_for(name)
          role_code = name.xpath(ROLE_CODE_XPATH, mods: DESC_METADATA_NS).first
          role_text = name.xpath(ROLE_TEXT_XPATH, mods: DESC_METADATA_NS).first
          return [] if role_code.nil? && role_text.nil?

          role_authority = name.xpath(ROLE_AUTHORITY_XPATH, mods: DESC_METADATA_NS).first
          role_authority_uri = name.xpath(ROLE_AUTHORITY_URI_XPATH, mods: DESC_METADATA_NS).first
          role_authority_value = name.xpath(ROLE_AUTHORITY_VALUE_XPATH, mods: DESC_METADATA_NS).first

          check_code(role_code, role_authority)

          {}.tap do |role|
            if role_authority&.content.present?
              role[:source] = { code: role_authority.content }
              role[:source][:uri] = role_authority_uri.content if role_authority_uri&.content.present?
            end

            role[:code] = role_code&.content
            role[:value] = role_text&.content
            role[:uri] = role_authority_value&.content

            if role[:code].blank? && role[:value].blank?
              Honeybadger.notify('[DATA ERROR] name/role/roleTerm missing value', { tags: 'data_error' })
              return []
            end
          end.compact
          # rubocop:enable Metrics/AbcSize
        end

        def type_for(type)
          unless Contributor::ROLES.keys.include?(type.downcase)
            Honeybadger.notify("[DATA ERROR] Contributor type unrecognized '#{type}'", { tags: 'data_error' })
            return
          end
          Honeybadger.notify('[DATA ERROR] Contributor type incorrectly capitalized', { tags: 'data_error' }) if type.downcase != type

          ROLES.fetch(type.downcase)
        end

        def check_code(role_code, role_authority)
          return if role_code.nil? || role_authority

          if role_code.content.present? && role_code.content.size == 3
            Honeybadger.notify('[DATA ERROR] Contributor role code is missing authority', { tags: 'data_error' })
            return
          end

          raise Cocina::Mapper::InvalidDescMetadata, "Contributor role code is missing and has unexpected value: #{role_code.content}"
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
