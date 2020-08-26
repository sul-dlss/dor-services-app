# frozen_string_literal: true

module Cocina
  # Validates that the structural.isMemberOf property references a Collection
  class CollectionExistenceValidator
    def initialize(item)
      @collection_id = item.structural&.isMemberOf
    end

    attr_reader :error

    # @return [Boolean] false if the object has a collection id that is not in the repository
    def valid?
      return true unless collection_id

      begin
        collection = Dor.find(collection_id)
        @error = "Expected '#{collection_id}' to be a Collection but it is a #{collection.class}" unless collection.is_a?(Dor::Collection)
      rescue ActiveFedora::ObjectNotFoundError
        @error = "Unable to find collection '#{collection_id}'"
      end

      @error.nil?
    end

    private

    attr_reader :collection_id
  end
end
