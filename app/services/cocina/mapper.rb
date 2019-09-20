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
        label: item.label,
        version: item.current_version.to_i # TODO: remove to_i after upgrading cocina-models to 0.5.0
      }

      # Collections don't have embargoMetadata
      if type == 'object' && item.embargoMetadata.release_date
        props[:access] = {
          embargoReleaseDate: item.embargoMetadata.release_date.iso8601
        }
      end

      props[:administrative] = build_administrative
      Cocina::Models::DRO.new(props)
    end

    private

    attr_reader :item

    def build_administrative
      {}.tap do |admin|
        admin[:releaseTags] = build_release_tags unless type == 'admin_policy'
      end
    end

    def build_release_tags
      item.identityMetadata.ng_xml.xpath('//release').map do |node|
        {
          to: node.attributes['to'].value,
          what: node.attributes['what'].value,
          date: node.attributes['when'].value,
          who: node.attributes['who'].value,
          release: node.text
        }
      end
    end

    # @todo This should have more speicific type such as found in identityMetadata.objectType
    def type
      case item
      when Dor::Item
        'object'
      when Dor::Collection
        'collection'
      when Dor::AdminPolicyObject
        'admin_policy'
      else
        raise "Unknown type for #{item.class}"
      end
    end
  end
end
