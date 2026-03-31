# frozen_string_literal: true

module Migrators
  # Helpers for counting, partitioning, and fetching migration batches.
  class BatchSupport
    BATCH_SIZE = 100

    # Returns a count of the druids to migrate, for the progress bar.
    def self.druids_count_for(migrator_class:, sample:)
      specific_druids = migrator_class.druids.presence
      if specific_druids
        specific_druids.size
      elsif sample
        [sample, RepositoryObject.count].min
      else
        RepositoryObject.count
      end
    end

    # Pre-computes batch descriptors in the parent process using a single keyset scan, so that
    # parallel workers can each fetch their own slice with an efficient indexed range query.
    # For migrators with specific druids (small lists): returns [batch_index, batch_size] pairs.
    # For DB-wide migrations: returns [after_id, limit] pairs where after_id is a PK boundary.
    #
    # @return [Array<Array(Integer, Integer)>] array of [index_or_after_id, limit] pairs
    # rubocop:disable Metrics/AbcSize
    def self.batch_descriptors(migrator_class:, sample:, batch_size: BATCH_SIZE)
      specific_druids = migrator_class.druids.presence
      if specific_druids
        druids = sample ? specific_druids.take(sample) : specific_druids
        druids.each_slice(batch_size).map.with_index { |slice, i| [i, slice.size] }
      else
        # Pluck only integer PKs once in parent to compute keyset boundaries (~8 bytes each).
        # Workers then fetch their slice via indexed WHERE id > after_id LIMIT n queries.
        scope = RepositoryObject.order(:id)
        scope = scope.limit(sample) if sample
        ids = scope.pluck(:id)
        slices = ids.each_slice(batch_size).to_a
        after_ids = [0] + slices[0..-2].map(&:last)
        slices.zip(after_ids).map { |slice, after_id| [after_id, slice.size] }
      end
    end
    # rubocop:enable Metrics/AbcSize

    # Returns the druids for a single batch using an indexed range query (keyset pagination).
    # Each parallel worker calls this after forking so that only a small slice is loaded
    # into each worker's memory.
    # @param batch_descriptor [Array(Integer, Integer)] a [index_or_after_id, limit] pair
    #   as returned by .batch_descriptors
    # @return [Array<String>] list of druids for the batch
    def self.druids_for_batch(migrator_class:, batch_descriptor:)
      index_or_after_id, limit = batch_descriptor
      Rails.logger.info("Fetching batch after_id=#{index_or_after_id} of druids to migrate...")
      specific_druids = migrator_class.druids.presence
      if specific_druids
        specific_druids.each_slice(BATCH_SIZE).to_a[index_or_after_id] || []
      else
        RepositoryObject.where('id > ?', index_or_after_id)
                        .order(:id)
                        .limit(limit)
                        .pluck(:external_identifier)
      end
    end
  end
end
