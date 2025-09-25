# frozen_string_literal: true

namespace :indexer do
  desc 'Reindex all objects in jobs'
  task :reindex_jobs, %i[batch_size] => :environment do |_task, args|
    results = SolrService.query('id:*', fl: 'id', rows: 10_000_000, wt: 'csv')
    druids = results.pluck('id')

    batches = druids.each_slice(args.batch_size&.to_i || 50)

    batches.each do |batch|
      BatchReindexJob.perform_later(batch)
    end
  end
end
