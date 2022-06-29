# frozen_string_literal: true

namespace :missing_druids do
  desc 'Find unindexed druids'
  task unindexed_objects: :environment do
    models = [AdminPolicy, Collection, Dro]
    druids_from_db = []
    druids_from_solr = []

    results = SolrService.query('id:*', fl: 'id', rows: 10_000_000, wt: 'csv')
    results.each { |r| druids_from_solr << r['id'] }

    models.each do |model|
      druids_from_db << model.all.pluck(:external_identifier)
    end

    missing_druids = druids_from_db.flatten.sort - druids_from_solr.sort
    File.open('missing_druids.txt', 'w') do |file|
      missing_druids.map { |druid| file.write("#{druid}\n") }
    end

    message = "Retrieved #{druids_from_solr.length} druids from SOLR\nRetrieved #{druids_from_db.flatten.length} druids from DB\nMissing #{missing_druids.length} druids in SOLR"
    puts message unless missing_druids.empty?
  end
end
