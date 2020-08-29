# frozen_string_literal: true

module Cocina
  # Validates that the structural.isMemberOf property references Collections
  class CollectionExistenceValidator
    def initialize(item)
      @collection_ids = Array.wrap(item.structural&.isMemberOf)
    end

    attr_reader :error

    # @return [Boolean] false if the object has a collection id that is not in the repository
    def valid?
      return true unless collection_ids.any?

      begin
        collection_ids.each do |collection_id|
          collection = Dor.find(collection_id)
          @error = "Expected '#{collection_id}' to be a Collection but it is a #{collection.class}" unless collection.is_a?(Dor::Collection)
        end
      rescue ActiveFedora::ObjectNotFoundError => e
        @error = "Unable to find collection: '#{e.message}'"
      end

      @error.nil?
    end

    private

    attr_reader :collection_ids
  end
end
