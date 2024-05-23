# frozen_string_literal: true

namespace :missing_druids do
  desc 'Find unindexed druids'
  task unindexed_objects: :environment do
    results = SolrService.query('id:*', fl: 'id', rows: 10_000_000, wt: 'csv')
    druids_from_solr = results.pluck('id')

    druids_from_db = RepositoryObject.order(external_identifier: :asc).pluck(:external_identifier)

    missing_druids = druids_from_db - druids_from_solr.sort
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
    File.readlines('missing_druids.txt').each do |line|
      druid = line.chomp
      puts "Indexing #{druid}"
      cocina_object = CocinaObjectStore.find(druid.chomp)
      Indexer.reindex(cocina_object:)
    end
  end
end
