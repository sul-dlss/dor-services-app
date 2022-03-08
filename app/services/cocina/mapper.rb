# frozen_string_literal: true

module Cocina
  # Maps Dor::Items to Cocina objects
  class Mapper
    # Generic base error class, so we can easily determine when a data error is one we
    # already account for, so that we can wrap the unexpected ones.
    class MapperError < StandardError; end

    # Raised when called on something other than an item (DRO), etd, collection, or adminPolicy (APO)
    class UnsupportedObjectType < MapperError; end

    # Raised when this object is missing a sourceID, so it can't be mapped to cocina.
    class MissingSourceID < MapperError
      def initialize(msg = 'Missing source ID')
        super(msg)
      end
    end

    # Raised on unexpected mapper failures. It is unknown if a data error or a mapping error.
    class UnexpectedBuildError < StandardError; end

    # @param [Dor::Abstract] item the Fedora object to convert to a cocina object
    # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy]
    # @param [Cocina::FromFedora::DataErrorNotifier] notifier
    # @raises [SolrConnectionError,UnsupportedObjectType,MissingSourceID]
    def self.build(item, notifier: nil)
      new(item, notifier: notifier).build
    end

    # @param [Dor::Abstract] item the Fedora object to convert to a cocina object
    def initialize(item, notifier: nil)
      @item = item
      @notifier = notifier
    end

    # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy]
    # @raises [SolrConnectionError, UnsupportedObjectType]
    def build
      klass = cocina_klass
      props = if klass == Cocina::Models::DRO
                FromFedora::DRO.props(item, notifier: notifier)
              elsif klass == Cocina::Models::Collection
                FromFedora::Collection.props(item, notifier: notifier)
              elsif klass == Cocina::Models::AdminPolicy
                FromFedora::APO.props(item, notifier: notifier)
              else
                raise "unable to build '#{klass}'"
              end
      klass.new(props)
    rescue StandardError => e
      new_message = "Unable to build cocina props - #{e.message}"
      Honeybadger.notify(new_message) # is this redundant?
      raise UnexpectedBuildError, new_message, e.backtrace # wrap StandardError, caller will probably want to look at #cause
    end

    private

    attr_reader :item, :notifier

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
