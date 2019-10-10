# frozen_string_literal: true

module Cocina
  # Maps Dor::Items to Cocina objects
  class Mapper
    # Raised when called on something other than an item or collection
    class UnsupportedObjectType < StandardError; end

    def self.build(item)
      new(item).build
    end

    def initialize(item)
      @item = item
    end

    def build
      klass = cocina_klass
      props = if klass == Cocina::Models::DRO
                dro_props
              elsif klass == Cocina::Models::Collection
                collection_props
              elsif klass == Cocina::Models::AdminPolicy
                apo_props
              else
                raise "unable to build '#{klass}'"
              end
      klass.new(props)
    end

    def dro_props
      {
        externalIdentifier: item.pid,
        type: Cocina::Models::DRO::TYPES.first,
        label: item.label,
        version: item.current_version,
        administrative: build_administrative
      }.tap do |props|
        if item.embargoMetadata.release_date
          props[:access] = {
            embargoReleaseDate: item.embargoMetadata.release_date.iso8601
          }
        end
      end
    end

    def collection_props
      {
        externalIdentifier: item.pid,
        type: Cocina::Models::Collection::TYPES.first,
        label: item.label,
        version: item.current_version,
        administrative: build_administrative
      }
    end

    def apo_props
      {
        externalIdentifier: item.pid,
        type: Cocina::Models::AdminPolicy::TYPES.first,
        label: item.label,
        version: item.current_version,
        administrative: build_administrative
      }
    end

    private

    attr_reader :item

    def build_administrative
      {}.tap do |admin|
        admin[:releaseTags] = build_release_tags
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
    def cocina_klass
      case item
      when Dor::Item
        Cocina::Models::DRO
      when Dor::Collection
        Cocina::Models::Collection
      when Dor::AdminPolicyObject
        Cocina::Models::AdminPolicy
      else
        raise UnsupportedObjectType, "Unknown type for #{item.class}"
      end
    end
  end
end
