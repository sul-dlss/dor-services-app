# frozen_string_literal: true

module Cocina
  # Validates that the structural.isMemberOf property references Collections
  class CollectionExistenceValidator
    def initialize(cocina_object)
      @collection_ids = Array.wrap(cocina_object.structural&.isMemberOf)
    end

    attr_reader :error

    # @return [Boolean] false if the object has a collection id that is not in the repository
    def valid?
      return true unless collection_ids.any?

      begin
        collection_ids.each do |collection_id|
          collection = CocinaObjectStore.find(collection_id)
          unless collection.collection?
            @error = "Expected '#{collection_id}' to be a Collection but it is a #{collection.class}"
          end
        end
      rescue CocinaObjectStore::CocinaObjectNotFoundError => e
        @error = "Unable to find collection: '#{e.message}'"
      end

      @error.nil?
    end

    private

    attr_reader :collection_ids
  end
end
