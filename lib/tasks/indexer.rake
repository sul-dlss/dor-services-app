# frozen_string_literal: true

namespace :indexer do
  desc 'Reindex all objects in jobs'
  task :reindex_jobs, %i[batch_size] => :environment do |_task, args|
    druids = RepositoryObject.pluck(:external_identifier)

    batches = druids.each_slice(args.batch_size&.to_i || 100)

    batches.each do |batch|
      BatchReindexJob.perform_later(batch)
    end
  end
end
