# frozen_string_literal: true

# Performs migration on a slice of druids.
class MigrationJob < ApplicationJob
  queue_as :migration

  # @param migrator_class [Class] the name of the migrator class to run
  # @param batch_descriptor [Array(Integer, Integer)] a [index_or_after_id, limit] pair
  #   as returned by MigrationRunner.batch_descriptors
  # @param mode [Symbol] the mode in which to operate on obj (see README for explanation of modes)
  # @param background_job_result [BackgroundJobResult] an object to store the result of the background job
  def perform(migrator_class:, batch_descriptor:, mode:, background_job_result:)
    background_job_result.processing!

    druids_slice = Migrators::MigrationRunner.druids_for_batch(migrator_class:, batch_descriptor:)

    results = Migrators::MigrationRunner.migrate_druid_list(migrator_class:, mode: mode,
                                                            druids_slice:).map do |result|
      [result[:id], result[:external_identifier], result[:status], result[:exception]]
    end

    background_job_result.update!(output: results, status: :complete)
  end
end
