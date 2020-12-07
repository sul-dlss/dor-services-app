# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Cocina
  module FromFedora
    class Descriptive
      # Maps a name
      class NameBuilder
        # @param [Nokogiri::XML::Element] name_element
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(name_element:, add_default_type: false)
          new(name_element: name_element, add_default_type: add_default_type).build
        end

        def initialize(name_element:, add_default_type: false)
          @name_element = name_element
          @add_default_type = add_default_type
        end

        def build
          {
            name: build_name_parts,
            type: type_for(name_element['type']),
            status: name_element['usage'],
            note: build_notes,
            identifier: build_identifier

          }.tap do |attrs|
            roles = build_roles
            attrs[:role] = roles unless attrs[:name].nil?
          end.compact
        end

        private

        attr_reader :name_element, :add_default_type

        def build_name_parts
          [].tap do |parts|
            query = name_element.xpath('mods:namePart', mods: DESC_METADATA_NS)
            if query.size == 1
              query.each do |name_part|
                parts << build_name_part(name_part).merge(authority_attrs).presence
              end
            else
              vals = query.map { |name_part| build_name_part(name_part).presence }.compact
              parts << { structuredValue: vals }.merge(authority_attrs)
            end

            display_form = name_element.xpath('mods:displayForm', mods: DESC_METADATA_NS).first
            parts << { value: display_form.text, type: 'display' } if display_form
          end.compact.presence
        end

        def build_name_part(name_part_node)
          if name_part_node.content.blank?
            Honeybadger.notify('[DATA ERROR] name/namePart missing value', { tags: 'data_error' })
            return {}
          end

          { value: name_part_node.content }.tap do |name_part|
            Honeybadger.notify('[DATA ERROR] name/namePart type attribute set to ""', { tags: 'data_error' }) if name_part_node['type'] == ''

            type = if add_default_type
                     Contributor::NAME_PART.fetch(name_part_node['type'], 'name')
                   elsif Contributor::NAME_PART.key? name_part_node['type']
                     Contributor::NAME_PART.fetch(name_part_node['type'])
                   elsif name_part_node['type'].present?
                     Honeybadger.notify("[DATA ERROR] namePart has unknown type assigned to it: '#{name_part_node['type']}'", { tags: 'data_error' })
                   end
            name_part[:type] = type if type
          end
        end

        def authority_attrs
          {
            uri: name_element['valueURI']

          }.tap do |attrs|
            source = {
              code: Authority.normalize_code(name_element['authority']),
              uri: Authority.normalize_uri(name_element['authorityURI'])
            }.compact
            attrs[:source] = source unless source.empty?
          end.compact
        end

        def build_identifier
          name_element.xpath('mods:nameIdentifier', mods: DESC_METADATA_NS).map { |identifier| IdentifierBuilder.build_from_name_identifier(identifier_element: identifier) }.presence
        end

        def build_notes
          [].tap do |parts|
            affiliation = name_element.xpath('mods:affiliation', mods: DESC_METADATA_NS).first
            parts << { value: affiliation.text, type: 'affiliation' } if affiliation

            description = name_element.xpath('mods:description', mods: DESC_METADATA_NS).first
            parts << { value: description.text, type: 'description' } if description
          end.presence
        end

        def names
          @names ||= resource_element.xpath(NAME_XPATH, mods: DESC_METADATA_NS)
        end

        def build_roles
          role_nodes = name_element.xpath('mods:role', mods: DESC_METADATA_NS)
          role_nodes.map do |role_node|
            role_for(role_node)
          end.compact.presence
        end

        ROLE_CODE_XPATH = './mods:roleTerm[@type="code"]'
        ROLE_TEXT_XPATH = './mods:roleTerm[@type="text"]'
        ROLE_AUTHORITY_XPATH = './mods:roleTerm/@authority'
        ROLE_AUTHORITY_URI_XPATH = './mods:roleTerm/@authorityURI'
        ROLE_AUTHORITY_VALUE_XPATH = './mods:roleTerm/@valueURI'
        MARC_RELATOR_PIECE = 'id.loc.gov/vocabulary/relators'

        # shameless green
        # rubocop:disable Metrics/AbcSize
        def role_for(ng_role)
          code = ng_role.xpath(ROLE_CODE_XPATH, mods: DESC_METADATA_NS).first
          text = ng_role.xpath(ROLE_TEXT_XPATH, mods: DESC_METADATA_NS).first
          return if code.nil? && text.nil?

          authority = ng_role.xpath(ROLE_AUTHORITY_XPATH, mods: DESC_METADATA_NS).first&.content
          authority_uri = ng_role.xpath(ROLE_AUTHORITY_URI_XPATH, mods: DESC_METADATA_NS).first&.content
          authority_value = ng_role.xpath(ROLE_AUTHORITY_VALUE_XPATH, mods: DESC_METADATA_NS).first&.content

          check_role_code(code, authority)

          {}.tap do |role|
            source = {
              code: Authority.normalize_code(authority),
              uri: authority == 'marcrelator' ? "http://#{MARC_RELATOR_PIECE}/" : Authority.normalize_uri(authority_uri)
            }.compact
            role[:source] = source if source.present?

            role[:uri] = authority_value
            role[:code] = code&.content
            marcrelator = marc_relator_role?(authority, authority_uri, authority_value)
            role[:value] = normalized_role_value(text.content, marcrelator) if text

            if role[:code].blank? && role[:value].blank?
              Honeybadger.notify('[DATA ERROR] name/role/roleTerm missing value', { tags: 'data_error' })
              return nil
            end
          end.compact
        end
        # rubocop:enable Metrics/AbcSize

        def type_for(type)
          return nil if type.blank?

          unless Contributor::ROLES.keys.include?(type.downcase)
            Honeybadger.notify("[DATA ERROR] Name type unrecognized '#{type}'", { tags: 'data_error' })
            return
          end
          Honeybadger.notify('[DATA ERROR] Name type incorrectly capitalized', { tags: 'data_error' }) if type.downcase != type

          Contributor::ROLES.fetch(type.downcase)
        end

        def check_role_code(role_code, role_authority)
          return if role_code.nil? || role_authority

          if role_code.content.present? && role_code.content.size == 3
            Honeybadger.notify('[DATA ERROR] Contributor role code is missing authority', { tags: 'data_error' })
            return
          end

          raise Cocina::Mapper::InvalidDescMetadata, "Contributor role code has unexpected value: #{role_code.content}"
        end

        # ensure value is downcased if it's a marcrelator value
        def normalized_role_value(value, marc_relator)
          marc_relator ? value.downcase : value
        end

        def marc_relator_role?(role_authority, role_authority_uri, role_authority_value)
          role_authority == 'marcrelator' ||
            role_authority_uri&.include?(MARC_RELATOR_PIECE) ||
            role_authority_value&.include?(MARC_RELATOR_PIECE)
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
