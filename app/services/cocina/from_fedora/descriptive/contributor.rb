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
              Honeybadger.notify('Data Error: name type attribute is set to ""', { tags: 'data_error' }) if name['type'] == ''

              # rubocop:disable Style/MultilineBlockChain
              contributors << { name: self.class.name_parts(name) }.tap do |contributor_hash|
                contributor_hash[:type] = type_for(name['type']) if name['type'].present?
                contributor_hash[:status] = name['usage'] if name['usage']
                roles = [roles_for(name)]
                contributor_hash[:role] = roles unless roles.flatten.empty? || contributor_hash[:name].blank?
                contributor_hash[:note] = notes_for(name)
                contributor_hash[:identifier] = identifier_for(name)
              end.reject { |_k, v| v.blank? } # it can be an empty array, so can't use .compact
              # rubocop:enable Style/MultilineBlockChain
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
          end.compact
        end

        def self.name_part(name_part_node, add_default_type:)
          if name_part_node.content.blank?
            Honeybadger.notify('Data Error: name/namePart missing value', { tags: 'data_error' })
            return
          end

          { value: name_part_node.content }.tap do |name_part|
            Honeybadger.notify('Data Error: name/namePart type attribute set to ""', { tags: 'data_error' }) if name_part_node['type'] == ''

            type = if add_default_type
                     NAME_PART.fetch(name_part_node['type'], 'name')
                   elsif name_part_node['type'].present?
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

        ROLE_CODE_XPATH = './mods:role/mods:roleTerm[@type="code"]'
        ROLE_TEXT_XPATH = './mods:role/mods:roleTerm[@type="text"]'
        ROLE_AUTHORITY_XPATH = './mods:role/mods:roleTerm/@authority'
        ROLE_AUTHORITY_URI_XPATH = './mods:role/mods:roleTerm/@authorityURI'
        ROLE_AUTHORITY_VALUE_XPATH = './mods:role/mods:roleTerm/@valueURI'

        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        def roles_for(name)
          role_code = name.xpath(ROLE_CODE_XPATH, mods: DESC_METADATA_NS).first
          role_text = name.xpath(ROLE_TEXT_XPATH, mods: DESC_METADATA_NS).first
          return [] if role_code.nil? && role_text.nil?

          role_authority = name.xpath(ROLE_AUTHORITY_XPATH, mods: DESC_METADATA_NS).first
          role_authority_uri = name.xpath(ROLE_AUTHORITY_URI_XPATH, mods: DESC_METADATA_NS).first
          role_authority_value = name.xpath(ROLE_AUTHORITY_VALUE_XPATH, mods: DESC_METADATA_NS).first

          {}.tap do |role|
            raise Cocina::Mapper::InvalidDescMetadata, "#{ROLE_CODE_XPATH} is missing required authority attribute" if role_code&.content.present? && role_authority&.content.blank?

            if role_authority&.content.present?
              role[:source] = { code: role_authority.content }
              role[:source][:uri] = role_authority_uri.content if role_authority_uri&.content.present?
            end

            role[:code] = role_code.content if role_code&.content.present?
            role[:value] = role_text.content if role_text&.content.present?
            role[:uri] = role_authority_value.content if role_authority_value&.content.present?
            unless role[:code] || role[:value]
              Honeybadger.notify('Data Error: name/role/roleTerm missing value', { tags: 'data_error' })
              return []
            end
          end
          # rubocop:enable Metrics/AbcSize
          # rubocop:enable Metrics/CyclomaticComplexity
          # rubocop:enable Metrics/PerceivedComplexity
        end

        def type_for(type)
          Honeybadger.notify('[DATA ERROR] Contributor type incorrectly capitalized', { tags: 'data_error' }) if type.downcase != type
          ROLES.fetch(type.downcase)
        end
      end
    end
  end
end
