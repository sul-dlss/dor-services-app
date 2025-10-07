# frozen_string_literal: true

BATCH_SIZE = 5

namespace :missing_druids do
  desc 'Find unindexed druids'
  task unindexed_objects: :environment do
    results = SolrService.query('id:*', fl: 'id', rows: 10_000_000, wt: 'csv')
    druids_from_solr = results.pluck('id')

    druids_from_db = RepositoryObject.order(updated_at: :desc).pluck(:external_identifier)

    missing_druids = druids_from_db - druids_from_solr
    File.open('missing_druids.txt', 'w') do |file|
      missing_druids.map { |druid| file.write("#{druid}\n") }
    end

    message = "Retrieved #{druids_from_solr.length} druids from SOLR\n"
    message << "Retrieved #{druids_from_db.flatten.length} druids from DB\n"
    message << "Missing #{missing_druids.length} druids in SOLR:\n\n"
    message << missing_druids.join("\n")

    puts message unless missing_druids.empty?
  end

  desc 'Index unindexed druids from missing_druids.txt'
  task index_unindexed_objects: :environment do
    solr_conn = RSolr.connect(timeout: 120, open_timeout: 120, url: Settings.solr.url)

    druids = File.readlines('missing_druids.txt', chomp: true)

    batches = druids.each_slice(BATCH_SIZE)
    batches.each_with_index(1) do |batch, index|
      batch_start_time = Time.zone.now
      solr_docs = Parallel.filter_map(batch, in_processes: 2) do |druid|
        cocina_object = CocinaObjectStore.find(druid)
        # This returns a Solr doc hash
        Indexing::Builders::DocumentBuilder.for(
          model: cocina_object,
          trace_id: Indexer.trace_id_for(druid:)
        ).to_solr
      rescue CocinaObjectStore::CocinaObjectNotFoundError
        # Return `nil`, which is compacted, so the Solr add isn't grumpy
        nil
      end

      solr_conn.add(solr_docs, add_attributes: { commitWithin: 500 })

      batch_end_time = Time.zone.now
      batch_run_seconds = (batch_end_time - batch_start_time).round(3)
      puts "#{Time.zone.now}\t#{index}\tIndexed #{BATCH_SIZE} documents in #{batch_run_seconds}\t"
    end
  end
end
