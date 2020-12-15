# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Sniffs value URIs
      class ValueURI
        SUPPORTED_PREFIXES = [
          'http'
        ].freeze

        def self.sniff(uri)
          Honeybadger.notify("[DATA ERROR] Value URI has unexpected value: #{uri}", tags: 'data_error') if uri.present? &&
                                                                                                           !uri.starts_with?(*SUPPORTED_PREFIXES)

          uri
        end
      end
    end
  end
end
