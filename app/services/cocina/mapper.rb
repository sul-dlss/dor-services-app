# frozen_string_literal: true

module Cocina
  # Maps Dor::Items to Cocina objects
  class Mapper
    # Raised when called on something other than an item (DRO), etd, collection, or adminPolicy (APO)
    class UnsupportedObjectType < StandardError; end

    # Raised when we can't figure out the title for the object.
    class MissingTitle < StandardError; end

    # @param [Dor::Abstract] item the Fedora object to convert to a cocina object
    # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy]
    def self.build(item)
      new(item).build
    end

    # @param [Dor::Abstract] item the Fedora object to convert to a cocina object
    def initialize(item)
      @item = item
    end

    # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy]
    def build
      klass = cocina_klass
      props = if klass == Cocina::Models::DRO
                FromFedora::DRO.props(item)
              elsif klass == Cocina::Models::Collection
                FromFedora::Collection.props(item)
              elsif klass == Cocina::Models::AdminPolicy
                FromFedora::APO.props(item)
              else
                raise "unable to build '#{klass}'"
              end
      klass.new(props)
    end

    private

    attr_reader :item

    # @todo This should have more specific type such as found in identityMetadata.objectType
    def cocina_klass
      case item
      when Dor::Item, Dor::Etd
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
