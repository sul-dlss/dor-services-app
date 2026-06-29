# frozen_string_literal: true

namespace :indexer do
  desc 'Reindex all objects in jobs'
  task :reindex_jobs, %i[batch_size] => :environment do |_task, args|
    RepositoryObject.in_batches(batch_size: args.batch_size&.to_i || 100) do |relation|
      druids = relation.pluck(:external_identifier)
      BatchReindexJob.perform_later(druids)
    end
  end
end
