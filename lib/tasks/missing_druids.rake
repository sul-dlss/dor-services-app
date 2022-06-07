# frozen_string_literal: true

namespace :missing_druids do
  desc 'Find unindexed druids'
  task unindexed_objects: :environment do
    models = [AdminPolicy, Collection, Dro]
    druids_from_db = []
    druids_from_solr = []

    loop do
      results = SolrService.query('id:*', fl: 'id', rows: 10_000_000, sort: 'id asc', wt: 'csv')
      break unless results.empty?

      results.each { |r| druids_from_solr << r['id'] }
      sleep(0.5)
    end
    puts "Retrieved #{druids_from_solr.length} druids from SOLR"

    models.each do |model|
      model.find_each do |object|
        druids_from_db << object.external_identifier
      end
    end
    puts "Retrieved #{druids_from_db.length} druids from DB"

    missing_druids = druids_from_db - druids_from_solr
    puts "Missing #{missing_druids.length} druids in SOLR"

    File.open('missing_druids.txt', 'w') do |file|
      missing_druids.map { |druid| file.write("#{druid}\n") }
    end
  end
end
