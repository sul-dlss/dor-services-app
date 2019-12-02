# frozen_string_literal: true

require 'cache'
class MetadataError < RuntimeError; end

class MetadataService
  VALID_PREFIXES = %w[catkey barcode].freeze

  class << self
    @@cache = Cache.new(nil, nil, 250, 300)

    # return the identifiers found in the same order of the known prefixes we specified
    def resolvable(identifiers)
      res_ids = identifiers.select { |identifier| can_resolve?(identifier) }
      VALID_PREFIXES.map { |prefix| res_ids.find { |res_id| res_id.start_with?(prefix.to_s) } }.compact
    end

    def fetch(identifier)
      @@cache.fetch(identifier) do
        (prefix, identifier) = identifier.split(/:/, 2)
        raise MetadataError, "Unknown metadata prefix: #{prefix}" unless VALID_PREFIXES.include?(prefix)

        marcxml = MarcxmlResource.find_by(prefix.to_sym => identifier)
        marcxml.mods
      end
    end

    def label_for(identifier)
      mods = Nokogiri::XML(fetch(identifier))
      mods.root.add_namespace_definition('mods', 'http://www.loc.gov/mods/v3')
      mods.xpath('/mods:mods/mods:titleInfo[1]').xpath('mods:title|mods:nonSort').collect(&:text).join(' ').strip
    end

    private

    def can_resolve?(identifier)
      (prefix, _identifier) = identifier.split(/:/, 2)
      VALID_PREFIXES.include?(prefix)
    end
  end
end
