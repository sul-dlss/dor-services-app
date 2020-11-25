# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Normalizes AuthorityURIs
      class AuthorityUri
        NORMALIZE_AUTHORITY_URIS = [
          'http://id.loc.gov/authorities/names',
          'http://id.loc.gov/authorities/subjects',
          'http://id.loc.gov/vocabulary/relators',
          'http://id.loc.gov/vocabulary/countries',
          'http://id.loc.gov/authorities/genreForms'
        ].freeze

        def self.normalize(authority_uri)
          return "#{authority_uri}/" if NORMALIZE_AUTHORITY_URIS.include?(authority_uri)

          authority_uri
        end
      end
    end
  end
end
