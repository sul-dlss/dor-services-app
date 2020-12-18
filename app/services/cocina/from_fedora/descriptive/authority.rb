# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Normalizes Authorities
      class Authority
        NORMALIZE_AUTHORITY_URIS = [
          'http://id.loc.gov/authorities/names',
          'http://id.loc.gov/authorities/subjects',
          'http://id.loc.gov/vocabulary/relators',
          'http://id.loc.gov/vocabulary/countries',
          'http://id.loc.gov/authorities/genreForms'
        ].freeze

        def self.normalize_uri(uri)
          return "#{uri}/" if NORMALIZE_AUTHORITY_URIS.include?(uri)

          uri.presence
        end

        def self.normalize_code(code)
          if code == 'lcnaf'
            Honeybadger.notify('[DATA ERROR] lcnaf authority code', tags: 'data_error')
            return 'naf'
          end

          if code == 'tgm'
            Honeybadger.notify('[DATA ERROR] tgm authority code (should be lctgm)', tags: 'data_error')
            return 'lctgm'
          end

          if code == '#N/A'
            # This is not a fatal problem. Just warn.
            Honeybadger.notify('[DATA ERROR] "#N/A" authority code', tags: 'data_error')
          end

          code.presence
        end
      end
    end
  end
end
