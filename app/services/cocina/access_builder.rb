# frozen_string_literal: true

module Cocina
  # builds the Access subschema for Collections
  class AccessBuilder
    def self.build(item)
      new(item).build
    end

    def initialize(item)
      @item = item
    end

    def build
      { access: access_rights }
    end

    private

    attr_reader :item

    # Map values from dor-services
    # https://github.com/sul-dlss/dor-services/blob/b9b4768eac560ef99b4a8d03475ea31fe4ae2367/lib/dor/datastreams/rights_metadata_ds.rb#L221-L228
    # to https://github.com/sul-dlss/cocina-models/blob/master/docs/maps/DRO.json#L102
    def access_rights
      item.rights.sub('None', 'citation-only').downcase
    end
  end
end
