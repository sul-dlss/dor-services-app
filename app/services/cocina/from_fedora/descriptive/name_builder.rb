# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Cocina
  module FromFedora
    class Descriptive
      # Maps a name
      class NameBuilder
        # @param [Array<Nokogiri::XML::Element>] name_elements (multiple if parallel)
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(name_elements:, add_default_type: false)
          new(name_elements: name_elements, add_default_type: add_default_type).build
        end

        def initialize(name_elements:, add_default_type: false)
          @name_elements = name_elements
          @add_default_type = add_default_type
        end

        def build
          if name_elements.size == 1
            build_name(name_elements.first)
          else
            build_parallel
          end
        end

        private

        attr_reader :name_elements, :add_default_type

        def build_parallel
          names = {
            parallelValue: name_elements.map { |name_node| build_parallel_name(name_node) },
            type: type_for(name_elements.first['type'])
          }.compact
          { name: [names] }.tap do |attrs|
            roles = name_elements.flat_map { |name_node| build_roles(name_node) }.compact.uniq
            attrs[:role] = roles.presence
          end.compact
        end

        def build_parallel_name(name_node)
          name_attrs = {
            status: name_node['usage']
          }.tap do |attrs|
            value_language = LanguageScript.build(node: name_node)
            attrs[:valueLanguage] = value_language if value_language
            if name_node[:transliteration] == 'ALA-LC Romanization Tables'
              attrs[:type] = 'transliteration'
              attrs[:standard] = {
                value: 'ALA-LC Romanization Tables'
              }
            end
          end

          name_attrs = name_attrs.merge(common_name(name_node, name_attrs[:name]))
          name_parts = build_name_parts(name_node)
          Honeybadger.notify('[DATA ERROR] missing name/namePart element', { tags: 'data_error' }) if name_parts.all?(&:empty?)
          name_parts.each { |name_part| name_attrs = name_attrs.merge(name_part) }
          name_attrs.compact
        end

        def build_name(name_node)
          name_parts = build_name_parts(name_node)
          # If there are no name parts, do not map the name
          if name_parts.all?(&:empty?)
            Honeybadger.notify('[DATA ERROR] missing name/namePart element', { tags: 'data_error' })
            return {}
          end
          {
            name: name_parts,
            type: type_for(name_node['type']),
            status: name_node['usage']
          }.compact.merge(common_name(name_node, name_parts))
        end

        def common_name(name_node, name)
          {
            note: build_notes(name_node),
            identifier: build_identifier(name_node)
          }.tap do |attrs|
            roles = build_roles(name_node)
            attrs[:role] = roles unless name.nil?
          end.compact
        end

        def build_name_parts(name_node)
          [].tap do |parts|
            query = name_node.xpath('mods:namePart', mods: DESC_METADATA_NS)
            case query.size
            when 0
              next # NOTE: #tap will return [] when there are no name parts
            when 1
              query.each do |name_part|
                parts << build_name_part(name_part).merge(authority_attrs_for(name_node)).presence
              end
            else
              vals = query.map { |name_part| build_name_part(name_part).presence }.compact
              parts << { structuredValue: vals }.merge(authority_attrs_for(name_node))
            end

            display_form = name_node.xpath('mods:displayForm', mods: DESC_METADATA_NS).first
            parts << { value: display_form.text, type: 'display' } if display_form
          end.compact
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

        def authority_attrs_for(name_node)
          {
            uri: ValueURI.sniff(name_node['valueURI'])
          }.tap do |attrs|
            source = {
              code: Authority.normalize_code(name_node['authority']),
              uri: Authority.normalize_uri(name_node['authorityURI'])
            }.compact
            attrs[:source] = source unless source.empty?
          end.compact
        end

        def build_identifier(name_node)
          name_node.xpath('mods:nameIdentifier', mods: DESC_METADATA_NS).map { |identifier| IdentifierBuilder.build_from_name_identifier(identifier_element: identifier) }.presence
        end

        def build_notes(name_node)
          [].tap do |parts|
            affiliation = name_node.xpath('mods:affiliation', mods: DESC_METADATA_NS).first
            parts << { value: affiliation.text, type: 'affiliation' } if affiliation

            description = name_node.xpath('mods:description', mods: DESC_METADATA_NS).first
            parts << { value: description.text, type: 'description' } if description
          end.presence
        end

        def build_roles(name_node)
          role_nodes = name_node.xpath('mods:role', mods: DESC_METADATA_NS)
          role_nodes.map do |role_node|
            role_for(role_node)
          end.compact.presence
        end

        MARC_RELATOR_PIECE = 'id.loc.gov/vocabulary/relators'

        # shameless green
        # rubocop:disable Metrics/AbcSize
        def role_for(ng_role)
          code = ng_role.xpath('./mods:roleTerm[@type="code"]', mods: DESC_METADATA_NS).first
          text = ng_role.xpath('./mods:roleTerm[@type="text"] | ./mods:roleTerm[not(@type)]', mods: DESC_METADATA_NS).first
          return if code.nil? && text.nil?

          authority = ng_role.xpath('./mods:roleTerm/@authority', mods: DESC_METADATA_NS).first&.content
          authority_uri = ng_role.xpath('./mods:roleTerm/@authorityURI', mods: DESC_METADATA_NS).first&.content
          authority_value = ng_role.xpath('./mods:roleTerm/@valueURI', mods: DESC_METADATA_NS).first&.content

          check_role_code(code, authority)

          {}.tap do |role|
            source = {
              code: Authority.normalize_code(authority),
              uri: authority == 'marcrelator' ? "http://#{MARC_RELATOR_PIECE}/" : Authority.normalize_uri(authority_uri)
            }.compact
            role[:source] = source if source.present?

            role[:uri] = ValueURI.sniff(authority_value)
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
