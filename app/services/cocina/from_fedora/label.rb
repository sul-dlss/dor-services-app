# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates label from a Fedora object
    class Label
      def self.for(fedora_object)
        # Label may have been truncated, so prefer objectLabel.
        (fedora_object.objectLabel.first || fedora_object.label)&.delete("\r")
      end
    end
  end
end
