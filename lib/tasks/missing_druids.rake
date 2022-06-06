# frozen_string_literal: true

namespace :missing_druids do
  desc 'Find unindexed druids'
  task unindexed_objects: :environment do
    druids = []

    models = [AdminPolicy, Collection, Dro]

    models.each do |model|
      model.find_each do |object|
        current_druid = object.external_identifier
        result = SolrService.query("id:#{current_druid}")
        next unless result.empty?

        puts "#{current_druid} (#{model}) not found in SOLR"
        druids << current_druid
      end
    end

    File.open('missing_druids.txt', 'w') do |file|
      druids.each do |druid|
        file.write("#{druid}\n")
      end
    end
  end
end
