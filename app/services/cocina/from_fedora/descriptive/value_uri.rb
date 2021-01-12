# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Sniffs value URIs
      class ValueURI
        SUPPORTED_PREFIXES = [
          'http'
        ].freeze

        def self.sniff(uri, notifier)
          notifier.warn('Value URI has unexpected value', { uri: uri }) if uri.present? && !uri.starts_with?(*SUPPORTED_PREFIXES)

          uri
        end
      end
    end
  end
end
