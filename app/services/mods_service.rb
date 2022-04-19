# frozen_string_literal: true

require 'cache'
class ModsServiceError < RuntimeError; end

# Service for fetching MODS from the catalog and associated helper methods.
class ModsService
  VALID_PREFIXES = %w[catkey barcode].freeze
  CATKEY_REGEX = /^\d+(:\d+)*$/.freeze

  class << self
    @@cache = Cache.new(nil, nil, 250, 300)

    # return the identifiers found in the same order of the known prefixes we specified
    def resolvable(identifiers)
      res_ids = identifiers.select { |identifier| can_resolve?(identifier) }
      VALID_PREFIXES.filter_map { |prefix| res_ids.find { |res_id| res_id.start_with?(prefix.to_s) } }
      # NOTE: the purpose of .map here is to ensure we return any resolvable identifiers in the
      #       preferred order specified above in KNOWN_PREFIXES, so that the .first is the preferred one
    end

    # @raises MarcService::MarcServiceError
    def fetch(identifier)
      @@cache.fetch(identifier) do
        (prefix, identifier) = parse_identifier(identifier)
        valid_identifier!(prefix, identifier)

        MarcService.mods(prefix.to_sym => identifier)
      end
    end

    def label_for(identifier)
      ModsUtils.label(Nokogiri::XML(fetch(identifier)))
    end

    private

    def can_resolve?(identifier)
      (prefix, _identifier) = parse_identifier(identifier)
      valid_prefix?(prefix)
    end

    def parse_identifier(identifier)
      identifier.split(/:/, 2)
    end

    def valid_catkey?(identifier)
      CATKEY_REGEX.match?(identifier)
    end

    def valid_identifier!(prefix, identifier)
      raise ModsServiceError, "Unknown metadata prefix: #{prefix}" unless valid_prefix?(prefix)
      raise ModsServiceError, "Invalid catkey: #{identifier}" unless valid_catkey?(identifier)
    end

    def valid_prefix?(prefix)
      VALID_PREFIXES.include?(prefix)
    end
  end
end
