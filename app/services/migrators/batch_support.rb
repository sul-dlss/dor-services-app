# frozen_string_literal: true

module Migrators
  # Helpers for counting, partitioning, and fetching migration batches.
  class BatchSupport
    # Pre-computes batch descriptors in the parent process using a single keyset scan, so that
    # parallel workers can each fetch their own slice with an efficient indexed range query.
    # @return [Array<Array(Integer, Integer)>] array of [index_or_after_id, limit] pairs
    def self.batch_descriptors(batch_size:, sample: nil)
      # Pluck only integer PKs once in parent to compute keyset boundaries (~8 bytes each).
      # Workers then fetch their slice via indexed WHERE id > after_id LIMIT n queries.
      scope = RepositoryObject.order(:id)
      scope = scope.limit(sample) if sample
      ids = scope.pluck(:id)
      slices = ids.each_slice(batch_size).to_a
      after_ids = [0] + slices[0..-2].map(&:last)
      slices.zip(after_ids).map { |slice, after_id| [after_id, slice.size] }
    end

    # Returns the druids for a single batch using an indexed range query (keyset pagination).
    # Each parallel worker calls this after forking so that only a small slice is loaded
    # into each worker's memory.
    # @param batch_descriptor [Array(Integer, Integer)] a [index_or_after_id, limit] pair
    #   as returned by .batch_descriptors
    # @return [Array<String>] list of druids for the batch
    def self.druids_for_batch(batch_descriptor:)
      index_or_after_id, limit = batch_descriptor
      RepositoryObject.where('id > ?', index_or_after_id)
                      .order(:id)
                      .limit(limit)
                      .pluck(:external_identifier)
    end

    # @return [Enumerator<Array<String>>] enumerator yielding batches of druids from the given file
    def self.slices_for_file(file:, batch_size:, sample: nil)
      druids = File.read(file).split.then do |druids|
        sample ? druids.take(sample) : druids
      end
      druids.each_slice(batch_size)
    end
  end
end
