# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Cocina
  module FromFedora
    class Descriptive
      # Maps a name
      class NameBuilder
        # @param [Array<Nokogiri::XML::Element>] name_elements (multiple if parallel)
        # @param [Cocina::FromFedora::DataErrorNotifier] notifier
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(name_elements:, notifier:)
          new(name_elements: name_elements, notifier: notifier).build
        end

        def initialize(name_elements:, notifier:)
          @name_elements = name_elements
          @notifier = notifier
        end

        def build
          if name_elements.size == 1
            build_name(name_elements.first)
          else
            build_parallel
          end
        end

        private

        attr_reader :name_elements, :notifier

        def build_parallel
          names = {
            parallelValue: name_elements.map { |name_node| build_parallel_name(name_node) },
            type: type_for(name_elements.first['type']),
            status: name_elements.map { |name_element| name_element['usage'] }.compact.first
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
          notifier.warn('Missing name/namePart element') if name_parts.all?(&:empty?)
          name_parts.each { |name_part| name_attrs = name_part.merge(name_attrs) }
          name_attrs.compact
        end

        def build_name(name_node)
          name_parts = build_name_parts(name_node)
          # If there are no name parts, do not map the name
          if name_parts.all?(&:empty?)
            notifier.warn('Missing name/namePart element')
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
            name_part_nodes = name_node.xpath('mods:namePart', mods: DESC_METADATA_NS)
            case name_part_nodes.size
            when 0
              parts << { valueAt: name_node['xlink:href'] } if name_node['xlink:href']
            when 1
              parts << build_name_part(name_node, name_part_nodes.first, default_type: false).merge(authority_attrs_for(name_node)).presence
            else
              vals = name_part_nodes.map { |name_part| build_name_part(name_node, name_part).presence }.compact
              parts << { structuredValue: vals }.merge(authority_attrs_for(name_node))
            end

            display_form = name_node.xpath('mods:displayForm', mods: DESC_METADATA_NS).first
            parts << { value: display_form.text, type: 'display' } if display_form
          end.compact
        end

        def build_name_part(name_node, name_part_node, default_type: true)
          if name_part_node.content.blank?
            notifier.warn('name/namePart missing value')
            return {}
          end

          {
            value: name_part_node.content,
            type: name_part_type_for(name_part_node['type'], default_type),
            displayLabel: name_node['displayLabel']
          }.compact
        end

        def name_part_type_for(type, default_type)
          notifier.warn('Name/namePart type attribute set to ""') if type == ''
          notifier.warn('namePart has unknown type assigned', type: type) if type.present? && !Contributor::NAME_PART.key?(type)

          if Contributor::NAME_PART.key?(type)
            Contributor::NAME_PART[type]
          elsif default_type && type.blank?
            'name'
          end
        end

        def authority_attrs_for(name_node)
          {
            uri: ValueURI.sniff(uri_for(name_node), notifier)
          }.tap do |attrs|
            source = {
              code: Authority.normalize_code(name_node['authority'], notifier),
              uri: Authority.normalize_uri(name_node['authorityURI'])
            }.compact
            attrs[:source] = source unless source.empty?
            attrs[:valueAt] = name_node['xlink:href'] unless xlink_is_value_uri?(name_node)
          end.compact
        end

        def uri_for(name_node)
          return name_node['valueURI'] if name_node['valueURI']

          return nil unless name_node['xlink:href'] && xlink_is_value_uri?(name_node)

          notifier.warn('Name has an xlink:href property')
          name_node['xlink:href']
        end

        def xlink_is_value_uri?(name_node)
          name_node['authority'] || name_node['authorityURI']
        end

        def build_identifier(name_node)
          name_node.xpath('mods:nameIdentifier', mods: DESC_METADATA_NS).map { |identifier| IdentifierBuilder.build_from_name_identifier(identifier_element: identifier) }.presence
        end

        def build_notes(name_node)
          [].tap do |parts|
            name_node.xpath('mods:affiliation', mods: DESC_METADATA_NS).each do |affiliation_node|
              parts << { value: affiliation_node.text, type: 'affiliation' }
            end

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
              code: Authority.normalize_code(authority, notifier),
              uri: Authority.normalize_uri(authority_uri)
            }.compact
            role[:source] = source if source.present?

            role[:uri] = ValueURI.sniff(authority_value, notifier)
            role[:code] = code&.content
            role[:value] = text.content if text

            if role[:code].blank? && role[:value].blank?
              notifier.warn('name/role/roleTerm missing value')
              return nil
            end
          end.compact
        end
        # rubocop:enable Metrics/AbcSize

        def type_for(type)
          return nil if type.blank?

          unless Contributor::ROLES.keys.include?(type.downcase)
            notifier.warn('Name type unrecognized', type: type)
            return
          end
          notifier.warn('Name type incorrectly capitalized', type: type) if type.downcase != type

          Contributor::ROLES.fetch(type.downcase)
        end

        def check_role_code(role_code, role_authority)
          return if role_code.nil? || role_authority

          if role_code.content.present? && role_code.content.size == 3
            notifier.warn('Contributor role code is missing authority')
            return
          end

          notifier.error('Contributor role code has unexpected value', role: role_code.content)
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
