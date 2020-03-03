# frozen_string_literal: true

module Cocina
  # builds the Access subschema for DROs and Collections
  class AccessBuilder
    def self.build(item)
      new(item).build
    end

    def initialize(item)
      @item = item
    end

    def build
      { access: access_rights }.tap do |access|
        embargo = build_embargo
        access[:embargo] = embargo unless embargo.empty?
        access[:useAndReproductionStatement] = item.rightsMetadata.use_statement.first if item.rightsMetadata.use_statement.first.present?
        access[:copyright] = item.rightsMetadata.copyright.first if item.rightsMetadata.copyright.first.present?
      end
    end

    private

    attr_reader :item

    # Map values from dor-services
    # https://github.com/sul-dlss/dor-services/blob/b9b4768eac560ef99b4a8d03475ea31fe4ae2367/lib/dor/datastreams/rights_metadata_ds.rb#L221-L228
    # to https://github.com/sul-dlss/cocina-models/blob/master/docs/maps/DRO.json#L102
    def access_rights
      item.rights.sub('None', 'citation-only').downcase
    end

    def build_embargo
      return {} unless item.respond_to?(:embargoMetadata) && item.embargoMetadata.release_date

      {
        releaseDate: item.embargoMetadata.release_date.iso8601,
        access: build_embargo_access
      }
    end

    def build_embargo_access
      access_node = item.embargoMetadata.release_access_node.xpath('//access[@type="read"]/machine/*[1]').first
      return 'dark' if access_node.nil?
      return 'world' if access_node.name == 'world'
      return access_node.content if access_node.name == 'group'

      'dark'
    end
  end
end
