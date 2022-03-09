# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the access schema to the Fedora 3 rights summary
    class Rights
      def self.rights_type(access)
        # DROAccess responds to controlledDigitalLending, but Access (for Collections) does not.
        return 'cdl-stanford-nd' if access.respond_to?(:controlledDigitalLending) && access.controlledDigitalLending

        case access.view
        when 'location-based'
          "loc:#{access.location}"
        when 'citation-only'
          'none'
        when 'dark'
          'dark'
        else
          access.respond_to?(:download) && access.download == 'none' ? "#{access.view}-nd" : access.view
        end
      end
    end
  end
end
