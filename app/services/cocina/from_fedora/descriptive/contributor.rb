# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Cocina
  module FromFedora
    class Descriptive
      # Maps contributors
      class Contributor
        # key: MODS, value: cocina
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

        NAME_XPATH = 'mods:name'
        NAME_PART_XPATH = './mods:namePart'

        # @param [Nokogiri::XML::Element] resource_element mods or relatedItem element
        # @param [Cocina::FromFedora::Descriptive::DescriptiveBuilder] descriptive_builder
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(resource_element:, descriptive_builder: nil)
          new(resource_element: resource_element).build
        end

        def initialize(resource_element:)
          @resource_element = resource_element
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

        attr_reader :resource_element

        def build_contributor_hash(name)
          { name: self.class.name_parts(name) }.tap do |contributor_hash|
            contributor_hash = name_authority_uri(name, contributor_hash)
            contributor_hash[:type] = type_for(name['type']) if name['type'].present?
            contributor_hash[:status] = name['usage'] if name['usage']
            roles = roles_for(name)
            contributor_hash[:role] = roles unless roles.flatten.empty? || contributor_hash[:name].blank?
            contributor_hash[:note] = notes_for(name)
            contributor_hash[:identifier] = identifier_for(name)
          end
        end

        def name_authority_uri(name_el, contributor_hash)
          value_uri = name_el.xpath('@valueURI', mods: DESC_METADATA_NS).first
          if value_uri&.content
            name_hash = contributor_hash[:name].first
            name_hash[:uri] = value_uri.content
            code = name_el.xpath('@authority', mods: DESC_METADATA_NS)&.first&.content
            source_uri = AuthorityUri.normalize(name_el.xpath('@authorityURI', mods: DESC_METADATA_NS)&.first&.content)
            name_hash[:source] = name_authority_source(code, source_uri) if code || source_uri
          end
          contributor_hash
        end

        def name_authority_source(code, uri)
          source = {
            code: code,
            uri: uri
          }.compact
          source.presence
        end

        def identifier_for(name)
          name.xpath('mods:nameIdentifier', mods: DESC_METADATA_NS).map { |identifier| IdentifierBuilder.build_from_name_identifier(identifier_element: identifier) }
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
          @names ||= resource_element.xpath(NAME_XPATH, mods: DESC_METADATA_NS)
        end

        def roles_for(name)
          ng_roles = name.xpath('mods:role', mods: DESC_METADATA_NS)
          ng_roles.map do |ng_role|
            role_hash(ng_role)
          end.compact
        end

        ROLE_CODE_XPATH = './mods:roleTerm[@type="code"]'
        ROLE_TEXT_XPATH = './mods:roleTerm[@type="text"]'
        ROLE_AUTHORITY_XPATH = './mods:roleTerm/@authority'
        ROLE_AUTHORITY_URI_XPATH = './mods:roleTerm/@authorityURI'
        ROLE_AUTHORITY_VALUE_XPATH = './mods:roleTerm/@valueURI'
        MARC_RELATOR_PIECE = 'id.loc.gov/vocabulary/relators'

        # shameless green
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        def role_hash(ng_role)
          code = ng_role.xpath(ROLE_CODE_XPATH, mods: DESC_METADATA_NS).first
          text = ng_role.xpath(ROLE_TEXT_XPATH, mods: DESC_METADATA_NS).first
          return if code.nil? && text.nil?

          authority = ng_role.xpath(ROLE_AUTHORITY_XPATH, mods: DESC_METADATA_NS).first
          authority_uri = ng_role.xpath(ROLE_AUTHORITY_URI_XPATH, mods: DESC_METADATA_NS).first
          authority_value = ng_role.xpath(ROLE_AUTHORITY_VALUE_XPATH, mods: DESC_METADATA_NS).first

          check_role_code(code, authority)

          {}.tap do |role|
            if authority&.content.present?
              role[:source] = { code: authority.content }
              if authority.content == 'marcrelator'
                role[:source][:uri] = "http://#{MARC_RELATOR_PIECE}/"
              elsif authority_uri&.content.present?
                role[:source][:uri] = AuthorityUri.normalize(authority_uri.content)
              end
            end

            role[:uri] = authority_value&.content
            role[:code] = code&.content
            marcrelator = marc_relator_role?(authority, authority_uri, authority_value)
            role[:value] = normalized_role_value(text.content, marcrelator) if text

            if role[:code].blank? && role[:value].blank?
              Honeybadger.notify('[DATA ERROR] name/role/roleTerm missing value', { tags: 'data_error' })
              return nil
            end
          end.compact
        end
        # rubocop:enable Metrics/PerceivedComplexity
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/AbcSize

        def type_for(type)
          unless Contributor::ROLES.keys.include?(type.downcase)
            Honeybadger.notify("[DATA ERROR] Contributor type unrecognized '#{type}'", { tags: 'data_error' })
            return
          end
          Honeybadger.notify('[DATA ERROR] Contributor type incorrectly capitalized', { tags: 'data_error' }) if type.downcase != type

          ROLES.fetch(type.downcase)
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
          role_authority&.content == 'marcrelator' ||
            role_authority_uri&.content&.include?(MARC_RELATOR_PIECE) ||
            role_authority_value&.content&.include?(MARC_RELATOR_PIECE)
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
