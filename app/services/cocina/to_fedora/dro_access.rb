# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the DROAccess schema to the
    # Fedora 3 data model rightsMetadata
    class DROAccess < Access
      def apply
        create_embargo(access.embargo) if access.embargo
        item.rightsMetadata.copyright = access.copyright if access.copyright
        item.rightsMetadata.use_statement = access.useAndReproductionStatement if access.useAndReproductionStatement

        super
      end

      private

      def create_embargo(embargo)
        EmbargoService.create(item: item,
                              release_date: embargo.releaseDate,
                              access: embargo.access,
                              use_and_reproduction_statement: embargo.useAndReproductionStatement)
      end
    end
  end
end
