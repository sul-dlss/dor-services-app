# frozen_string_literal: true

module Cocina
  # Maps Dor::Items to Cocina objects
  class Mapper
    def self.build(item)
      new(item).build
    end

    def initialize(item)
      @item = item
    end

    def build
      props = {
        externalIdentifier: item.pid,
        type: type,
        label: item.label
      }

      # Collections don't have embargoMetadata
      if type == 'object' && item.embargoMetadata.release_date
        props[:access] = {
          embargoReleaseDate: item.embargoMetadata.release_date.iso8601
        }
      end
      Cocina::Models::DRO.new(props)
    end

    private

    attr_reader :item

    # @todo This should have more speicific type such as found in identityMetadata.objectType
    def type
      case item
      when Dor::Item
        'object'
      when Dor::Collection
        'collection'
      else
        raise "Unknown type for #{item.class}"
      end
    end
  end
end
