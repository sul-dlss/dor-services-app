# frozen_string_literal: true

module Cocina
  module FromFedora
    module Access
      # Finds the use statement.
      class UseStatement
        # @return [String] the use statement.
        def self.find(datastream)
          datastream.use_statement.first.presence
        end
      end
    end
  end
end
