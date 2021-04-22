# frozen_string_literal: true

module Cocina
  module FromFedora
    module Access
      # Finds the copyright.
      class Copyright
        # @return [String] the copyright.
        def self.find(datastream)
          datastream.copyright.first.presence
        end
      end
    end
  end
end
