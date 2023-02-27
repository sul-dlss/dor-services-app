# frozen_string_literal: true

module Migrators
  # Migrator that adds Folio catalog links.
  class Folio < Base
    # A migrator must implement a migrate? method that returns true if the SDR object should be migrated.
    def migrate?
      return false if ar_cocina_object.is_a?(AdminPolicy)

      Set.new(catalog_links_for(cocina_object)) != Set.new(catalog_links_for(migrated_cocina_object))
    end

    def migrate
      ar_cocina_object[:identification] = migrated_cocina_object.identification.to_h
    end

    private

    def catalog_links_for(cocina_object)
      Array(cocina_object.identification&.catalogLinks)
    end

    def cocina_object
      @cocina_object ||= ar_cocina_object.to_cocina
    end

    def migrated_cocina_object
      @migrated_cocina_object ||= Catalog::AddFolioCatalogLinksService.add(cocina_object)
    end
  end
end
